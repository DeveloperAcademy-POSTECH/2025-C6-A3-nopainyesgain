//
//  KeyringBundleItem.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

// 뭉치 보관함 그리드에 들어가는 각각의 아이템 컴포넌트입니다
import SwiftUI

struct KeyringBundleItem: View {
    let bundle: KeyringBundle
    let screenSize: CGSize

    @State private var cachedImage: Image?
    @State private var isCapturing: Bool = false

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .top) {
                // 캐시된 번들 이미지 표시
                bundleImageView
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    )
                if bundle.isMain {
                    UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                        .fill(.pink100.opacity(0.7))
                        .overlay(
                            Text("대표")
                                .typography(.suit13M)
                                .foregroundStyle(.white100)
                        )
                        .frame(height: 26)
                        .frame(maxWidth: .infinity)
                    
                }
            }
            
            HStack {
                Text(bundle.name)
                    .typography(.suit15SB25)
                    .foregroundStyle(.black100)
                Spacer()
            }
            HStack {
                Text("걸린 키링")
                    .typography(.suit12M)
                    .foregroundStyle(.gray500)
                Spacer()
                Text("\(bundle.keyrings.count) / \(bundle.maxKeyrings) 개")
                    .typography(.suit12M)
                    .foregroundStyle(.main500)
            }
        }
        .onAppear {
            loadBundleImage()
        }
    }

    // MARK: - Bundle Image View

    private var bundleImageView: some View {
        return Group {
            if isCapturing {
                // 캡처 중 ProgressView
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            } else if let cachedImage = cachedImage {
                cachedImage
                    .resizable()
                    .scaledToFit()
            } else {
                // 캐시 로딩 중 또는 실패 시 플레이스홀더
                Image(.ddochi)
                    .resizable()
                    .scaledToFit()
            }
        }
    }

    // MARK: - Load Bundle Image

    /// 캐시에서 번들 이미지 로드
    private func loadBundleImage() {
        guard let documentId = bundle.documentId else {
            print("⚠️ [BundleItem] documentId 없음")
            return
        }

        // 캐시에서 이미지 로드
        if let imageData = BundleImageCache.shared.load(for: documentId),
           let uiImage = UIImage(data: imageData) {
            cachedImage = Image(uiImage: uiImage)
//            print("✅ [BundleItem] 캐시 이미지 로드: \(bundle.name)")
        } else {
            print("⚠️ [BundleItem] 캐시 이미지 없음: \(bundle.name) - 재캡처 시작")
            // 캐시가 없으면 다시 캡처
            Task {
                await recaptureAndCacheBundleImage(bundleId: documentId, bundleName: bundle.name)
            }
        }
    }

    // MARK: - Recapture Bundle Image

    /// 번들 이미지 재캡처 및 캐시 저장
    private func recaptureAndCacheBundleImage(bundleId: String, bundleName: String) async {
        await MainActor.run {
            isCapturing = true
        }

        // Firestore에서 번들 정보 가져오기 (배경, 카라비너, 키링 정보)
        guard let background = await fetchBackgroundInfo(backgroundId: bundle.selectedBackground),
              let carabiner = await fetchCarabinerInfo(carabinerId: bundle.selectedCarabiner) else {
            print("❌ [BundleItem] 배경 또는 카라비너 정보를 가져올 수 없습니다")
            await MainActor.run {
                isCapturing = false
            }
            return
        }

        // 키링 정보 가져오기
        let keyringInfoList = await fetchKeyringInfoList(keyringIds: bundle.keyrings)

        // 키링 데이터 생성
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []

        for (index, keyringInfo) in keyringInfoList.enumerated() {
            guard index < carabiner.keyringXPosition.count,
                  index < carabiner.keyringYPosition.count else {
                continue
            }

            let data = MultiKeyringCaptureScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyringInfo.bodyImage
            )
            keyringDataList.append(data)
        }

        // 배경 이미지 미리 로드 (캡처 전 확인)
        print("🔄 [BundleItem] 배경 이미지 미리 로드 시작: \(background.backgroundImage)")
        guard let _ = try? await StorageManager.shared.getImage(path: background.backgroundImage) else {
            print("❌ [BundleItem] 배경 이미지 미리 로드 실패")
            await MainActor.run {
                isCapturing = false
            }
            return
        }
        print("✅ [BundleItem] 배경 이미지 미리 로드 완료")

        // screenSize로 캡처 (부모에서 전달받은 화면 크기 사용)
        print("📐 [BundleItem] 재캡처 크기: \(screenSize.width) x \(screenSize.height)")

        // 카라비너 이미지 추출 (hamburger 타입인 경우)
        let carabinerType = CarabinerType.from(carabiner.carabinerType)
        let carabinerBackURL: String? = carabinerType == .hamburger ? carabiner.carabinerImage[1] : nil
        let carabinerFrontURL: String? = carabinerType == .hamburger ? carabiner.carabinerImage[2] : nil

        if let pngData = await MultiKeyringCaptureScene.captureBundleImageWithGeometry(
            keyringDataList: keyringDataList,
            backgroundImageURL: background.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            viewSize: screenSize
        ) {
            // BundleImageCache에 저장
            BundleImageCache.shared.syncBundle(
                id: bundleId,
                name: bundleName,
                imageData: pngData
            )

            // UI 업데이트
            if let uiImage = UIImage(data: pngData) {
                await MainActor.run {
                    cachedImage = Image(uiImage: uiImage)
                    isCapturing = false
                }
            }
            print("✅ [BundleItem] 번들 이미지 재캡처 및 캐시 저장 완료: \(bundleName)")
        } else {
            print("❌ [BundleItem] 재캡처 실패: \(bundleId)")
            await MainActor.run {
                isCapturing = false
            }
        }
    }

    // MARK: - Fetch Helper Methods

    /// 배경 정보 가져오기
    private func fetchBackgroundInfo(backgroundId: String) async -> Background? {
        // WorkshopDataManager에서 배경 정보 가져오기
        await WorkshopDataManager.shared.fetchBackgroundsIfNeeded()
        return WorkshopDataManager.shared.backgrounds.first { $0.id == backgroundId }
    }

    /// 카라비너 정보 가져오기
    private func fetchCarabinerInfo(carabinerId: String) async -> Carabiner? {
        // WorkshopDataManager에서 카라비너 정보 가져오기
        await WorkshopDataManager.shared.fetchCarabinersIfNeeded()
        return WorkshopDataManager.shared.carabiners.first { $0.id == carabinerId }
    }

    /// 키링 정보 목록 가져오기
    private func fetchKeyringInfoList(keyringIds: [String]) async -> [KeyringInfo] {
        var keyringInfoList: [KeyringInfo] = []

        for keyringId in keyringIds {
            // "none"은 스킵
            guard keyringId != "none" else { continue }

            // Firestore에서 키링 정보 가져오기
            if let keyringInfo = await fetchKeyringFromFirestore(keyringId: keyringId) {
                keyringInfoList.append(keyringInfo)
            }
        }

        return keyringInfoList
    }

    /// Firestore에서 키링 정보 가져오기
    private func fetchKeyringFromFirestore(keyringId: String) async -> KeyringInfo? {
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let document = try await db.collection("Keyring").document(keyringId).getDocument()

            guard let data = document.data(),
                  let bodyImage = data["bodyImage"] as? String else {
                return nil
            }

            return KeyringInfo(id: keyringId, bodyImage: bodyImage)
        } catch {
            print("❌ [BundleItem] 키링 정보 로드 실패: \(keyringId) - \(error.localizedDescription)")
            return nil
        }
    }

    /// 키링 정보 구조체 (최소 정보만)
    struct KeyringInfo {
        let id: String
        let bodyImage: String
    }
}

import SpriteKit
import FirebaseFirestore
