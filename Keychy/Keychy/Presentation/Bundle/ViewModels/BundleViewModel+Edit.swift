//
//  BundleViewModel+Edit.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

import SwiftUI

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
}
