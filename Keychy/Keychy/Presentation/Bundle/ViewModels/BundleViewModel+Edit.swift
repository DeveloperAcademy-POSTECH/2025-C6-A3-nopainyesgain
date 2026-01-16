//
//  BundleViewModel+Edit.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

import SwiftUI
import FirebaseFirestore

extension BundleViewModel {
    /// 선택된 키링들로부터 키링 데이터 리스트 생성 (편집용)
    func createKeyringDataListFromSelected(
        selectedKeyrings: [Int: Keyring],
        keyringOrder: [Int],
        carabiner: Carabiner
    ) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []
        
        // 추가된 순서대로 처리
        for index in keyringOrder {
            guard let keyring = selectedKeyrings[index] else { continue }
            let soundId = keyring.soundId
            
            // 커스텀 사운드 URL 처리
            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()
            
            let particleId = keyring.particleId
            
            // 절대 좌표 사용 (이미 절대 좌표로 저장됨)
            let position = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )

            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: position,
                bodyImageURL: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: particleId,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength
            )
            dataList.append(data)
        }

        return dataList
    }

    /// 뭉치에서 현재 키링들을 selectedKeyrings 형태로 변환
    func convertBundleToSelectedKeyrings(bundle: KeyringBundle) async -> ([Int: Keyring], [Int]) {
        var selectedKeyrings: [Int: Keyring] = [:]
        var keyringOrder: [Int] = []
        
        for (index, keyringId) in bundle.keyrings.enumerated() {
            guard keyringId != "none", !keyringId.isEmpty else { continue }
            
            // 사용자의 키링 목록에서 해당 키링 찾기 (documentId로 비교)
            if let keyring = self.keyring.first(where: { $0.documentId == keyringId }) {
                selectedKeyrings[index] = keyring
                keyringOrder.append(index)
            }
        }
        
        return (selectedKeyrings, keyringOrder)
    }
    
    /// selectedKeyrings를 뭉치 형태의 키링 배열로 변환
    func convertSelectedKeyringsToBundleFormat(
        selectedKeyrings: [Int: Keyring],
        maxKeyringCount: Int
    ) -> [String] {
        var keyrings = Array(repeating: "none", count: maxKeyringCount)
        
        for (index, keyring) in selectedKeyrings {
            if index < maxKeyringCount {
                keyrings[index] = keyring.documentId ?? "none"
            }
        }
        
        return keyrings
    }
    
    // 뭉치 편집뷰에서 화면이 다시 나타날 때 데이터 새로고침 (구매 상태 업데이트) 메서드
    func refreshEditData() async {
        // 현재 선택된 아이템의 ID 저장
        let currentBackgroundId = newSelectedBackground?.background.id
        let currentCarabinerId = newSelectedCarabiner?.carabiner.id
        
        // 배경 데이터 새로고침
        await withCheckedContinuation { continuation in
            fetchAllBackgrounds { _ in
                // 이전에 선택했던 배경을 다시 찾아서 선택 (구매 상태가 업데이트됨)
                if let bgId = currentBackgroundId {
                    self.newSelectedBackground = self.backgroundViewData.first { $0.background.id == bgId }
                }
                continuation.resume()
            }
        }
        
        // 카라비너 데이터 새로고침
        await withCheckedContinuation { continuation in
            fetchAllCarabiners { _ in
                // 이전에 선택했던 카라비너를 다시 찾아서 선택 (구매 상태가 업데이트됨)
                if let cbId = currentCarabinerId {
                    self.newSelectedCarabiner = self.carabinerViewData.first { $0.carabiner.id == cbId }
                }
                continuation.resume()
            }
        }
    }
    
    // 뭉치 변경사항을 Firebase에 저장
    
    func saveBundleChanges() async {
        guard let bundle = selectedBundle,
              let documentId = bundle.documentId,
              let background = newSelectedBackground,
              let carabiner = newSelectedCarabiner else {
            return
        }
        
        // ID 안전성 체크
        guard let backgroundId = background.background.id,
              let carabinerId = carabiner.carabiner.id else {
            return
        }
        
        // 변경사항 체크: 원본 번들과 현재 선택된 항목 비교
        let isBackgroundChanged = bundle.selectedBackground != backgroundId
        let isCarabinerChanged = bundle.selectedCarabiner != carabinerId
        
        // 키링 변경사항 체크
        let currentKeyrings = convertSelectedKeyringsToBundleFormat(
            selectedKeyrings: selectedKeyrings,
            maxKeyringCount: carabiner.carabiner.maxKeyringCount
        ).map { $0.isEmpty ? "none" : $0 }
        
        let isKeyringsChanged = bundle.keyrings != currentKeyrings
        
        // 변경사항이 전혀 없으면 저장하지 않고 즉시 리턴
        if !isBackgroundChanged && !isCarabinerChanged && !isKeyringsChanged {
            return
        }
        
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let updateData: [String: Any] = [
                "keyrings": currentKeyrings,
                "selectedBackground": backgroundId,
                "selectedCarabiner": carabinerId
            ]
            try await db.collection("KeyringBundle").document(documentId).updateData(updateData)
            
            // 로컬 상태도 업데이트
            await MainActor.run {
                if let index = bundles.firstIndex(where: { $0.documentId == documentId }) {
                    bundles[index].keyrings = currentKeyrings
                    bundles[index].selectedBackground = backgroundId
                    bundles[index].selectedCarabiner = carabinerId
                }
                
                // selectedBundle도 업데이트
                if selectedBundle?.documentId == documentId {
                    selectedBundle?.keyrings = currentKeyrings
                    selectedBundle?.selectedBackground = backgroundId
                    selectedBundle?.selectedCarabiner = carabinerId
                }
                
                // 캐시 삭제, BundleInventoryView로 접근했을 때 썸네일 업데이트 하도록 함
                BundleImageCache.shared.delete(for: documentId)
            }
            
        } catch {
            print("❌ Firebase 업데이트 실패: \(error.localizedDescription)")
            if let firestoreError = error as NSError? {
                print("Firebase 에러 코드: \(firestoreError.code)")
                print("Firebase 에러 도메인: \(firestoreError.domain)")
                print("Firebase 에러 상세: \(firestoreError.userInfo)")
            }
        }
    }
}
