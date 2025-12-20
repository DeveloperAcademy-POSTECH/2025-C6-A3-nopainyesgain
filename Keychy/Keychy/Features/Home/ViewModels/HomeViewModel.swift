//
//  HomeViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/16/24.
//

import SwiftUI
import FirebaseFirestore

@Observable
class HomeViewModel {
    // MARK: - Properties

    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    var keyringDataList: [MultiKeyringScene.KeyringData] = []

    /// 씬 준비 완료 여부
    var isSceneReady = false
    
    /// 데이터 로드 완료 여부
    var isDataLoaded = false

    // MARK: - Private Properties

    private let db = Firestore.firestore()

    // MARK: - Data Loading

    /// 메인 뭉치 데이터를 로드하고 뷰 상태를 초기화
    /// 1. 사용자의 모든 뭉치 목록을 가져옴
    /// 2. 메인으로 설정된 뭉치를 찾아 선택
    /// 3. 선택된 뭉치의 키링들을 Firestore에서 가져와 KeyringData 리스트 생성
    
    /// Firestore에서 가져온 키링 정보를 담는 구조체
    struct KeyringInfo {
        let id: String
        let bodyImage: String
        let selectedTemplate: String?
        let soundId: String
        let particleId: String
        let hookOffsetY: CGFloat?
        let chainLength: Int
    }
    
    @MainActor
    func loadMainBundle(collectionViewModel: CollectionViewModel, onBackgroundLoaded: (() -> Void)?) async {
        let uid = UserManager.shared.userUID
        guard !uid.isEmpty else { return }

        // 1. 배경 및 카라비너 데이터 로드
        await collectionViewModel.loadBackgroundsAndCarabiners()

        // 2. 번들 목록 로드
        await withCheckedContinuation { continuation in
            collectionViewModel.fetchAllBundles(uid: uid) { _ in
                continuation.resume()
            }
        }

        // 3. 메인 뭉치 설정 (isMain == true인 뭉치, 없으면 첫 번째 뭉치)
        if let mainBundle = collectionViewModel.sortedBundles.first(where: { $0.isMain }) {
            collectionViewModel.selectedBundle = mainBundle
        } else if let firstBundle = collectionViewModel.sortedBundles.first {
            collectionViewModel.selectedBundle = firstBundle
        } else {
            // 번들이 하나도 없는 경우 - 스플래시 즉시 종료
            onBackgroundLoaded?()
            return
        }

        // 4. 선택된 뭉치의 배경과 카라비너 설정
        guard var bundle = collectionViewModel.selectedBundle else { return }

        // 배경 resolve 시도
        var resolvedBackground = collectionViewModel.resolveBackground(from: bundle.selectedBackground)

        // 배경이 없으면 첫 번째 배경으로 업데이트
        if resolvedBackground == nil, let firstBackground = collectionViewModel.backgrounds.first {
            resolvedBackground = firstBackground

            // Firebase에 번들의 배경 업데이트
            if let documentId = bundle.documentId, let backgroundId = firstBackground.id {
                await updateBundleBackground(documentId: documentId, backgroundId: backgroundId)

                // 로컬 상태도 업데이트
                bundle.selectedBackground = backgroundId
                collectionViewModel.selectedBundle?.selectedBackground = backgroundId
                if let index = collectionViewModel.bundles.firstIndex(where: { $0.documentId == documentId }) {
                    collectionViewModel.bundles[index].selectedBackground = backgroundId
                }
            }
        }

        collectionViewModel.selectedBackground = resolvedBackground
        collectionViewModel.selectedCarabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner)

        // 5. 키링 데이터 생성
        guard let carabiner = collectionViewModel.selectedCarabiner else { return }
        keyringDataList = await createKeyringDataList(bundle: bundle, carabiner: carabiner)
        
        // 데이터 로드 완료 표시
        isDataLoaded = true
    }

    /// 뭉치의 키링들을 MultiKeyringScene.KeyringData 배열로 변환
    /// - Parameters:
    ///   - bundle: 현재 뭉치
    ///   - carabiner: 선택된 카라비너 (위치 정보 제공)
    /// - Returns: 3D 씬에서 사용할 KeyringData 배열
    private func createKeyringDataList(bundle: KeyringBundle, carabiner: Carabiner) async -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        for (index, keyringId) in bundle.keyrings.enumerated() {
            // 유효하지 않은 키링 ID 필터링
            guard index < carabiner.maxKeyringCount,
                  keyringId != "none",
                  !keyringId.isEmpty else { continue }

            // Firebase에서 키링 정보 가져오기
            guard let keyringInfo = await fetchKeyringInfo(keyringId: keyringId) else { continue }

            // 커스텀 사운드 URL 처리 (HTTP/HTTPS로 시작하는 경우)
            let customSoundURL: URL? = {
                if keyringInfo.soundId.hasPrefix("https://") || keyringInfo.soundId.hasPrefix("http://") {
                    return URL(string: keyringInfo.soundId)
                }
                return nil
            }()

            // KeyringData 생성
            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyringInfo.bodyImage,
                templateId: keyringInfo.selectedTemplate,
                soundId: keyringInfo.soundId,
                customSoundURL: customSoundURL,
                particleId: keyringInfo.particleId,
                hookOffsetY: keyringInfo.hookOffsetY,
                chainLength: keyringInfo.chainLength
            )
            dataList.append(data)
        }

        return dataList
    }

    /// Firestore에서 키링 정보를 가져옴
    private func fetchKeyringInfo(keyringId: String) async -> KeyringInfo? {
        do {
            let document = try await db.collection("Keyring").document(keyringId).getDocument()

            guard let data = document.data(),
                  let bodyImage = data["bodyImage"] as? String,
                  let soundId = data["soundId"] as? String,
                  let particleId = data["particleId"] as? String else {
                return nil
            }

            let hookOffsetY = data["hookOffsetY"] as? CGFloat ?? 0.0
            let chainLength = data["chainLength"] as? Int ?? 5
            let selectedTemplate = data["selectedTemplate"] as? String

            return KeyringInfo(
                id: keyringId,
                bodyImage: bodyImage,
                selectedTemplate: selectedTemplate,
                soundId: soundId,
                particleId: particleId,
                hookOffsetY: hookOffsetY,
                chainLength: chainLength
            )
        } catch {
            return nil
        }
    }

    /// 번들의 배경을 Firebase에 업데이트
    private func updateBundleBackground(documentId: String, backgroundId: String) async {
        do {
            try await db.collection("KeyringBundle").document(documentId).updateData([
                "selectedBackground": backgroundId
            ])
        } catch {
            print("[HomeView] 뭉치 배경 업데이트 실패: \(error.localizedDescription)")
        }
    }

    /// 키링 데이터 변경 감지 시 씬 준비 상태 초기화
    func handleKeyringDataChange() {
        withAnimation(.easeIn(duration: 0.2)) {
            isSceneReady = false
        }
    }

    /// 모든 키링 준비 완료 처리
    func handleAllKeyringsReady() {
        
        // 데이터가 로드되지 않았으면 준비 완료하지 않음
        guard isDataLoaded else {
            return
        }
        
        // 물리 엔진 안정화를 위한 딜레이만 적용 (0.5초)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    isSceneReady = true
                }
            }
        }
    }

}
