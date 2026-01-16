//
//  BundleViewModel+Sort.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

import Foundation

extension BundleViewModel {
    // MARK: - 키링 선택 시트 키링 정렬
    /// 키링 선택 시트용 정렬된 키링 리스트
    /// 1순위: 현재 위치에 선택된 키링
    /// 2순위: 일반 키링들 (선택되지 않고, published/packaged 아님)
    /// 3순위: 다른 위치에 장착된 키링들
    /// 4순위: published 또는 packaged 상태의 키링들 (맨 뒤)
    func sortedKeyringsForSelection(selectedKeyrings: [Int: Keyring], selectedPosition: Int) -> [Keyring] {
        let selectedKeyring = selectedKeyrings[selectedPosition]
        
        return keyring.sorted { keyring1, keyring2 in
            let isKeyring1SelectedHere = keyring1.id == selectedKeyring?.id
            let isKeyring2SelectedHere = keyring2.id == selectedKeyring?.id
            
            let isKeyring1SelectedElsewhere = selectedKeyrings.values.contains { $0.id == keyring1.id } && !isKeyring1SelectedHere
            let isKeyring2SelectedElsewhere = selectedKeyrings.values.contains { $0.id == keyring2.id } && !isKeyring2SelectedHere
            
            let isKeyring1Unavailable = keyring1.status == .published || keyring1.status == .packaged
            let isKeyring2Unavailable = keyring2.status == .published || keyring2.status == .packaged
            
            // 1순위: 현재 위치에 선택된 키링 - 맨 앞
            if isKeyring1SelectedHere != isKeyring2SelectedHere {
                return isKeyring1SelectedHere
            }
            
            // 2순위: 일반 키링 vs 나머지 (elsewhere or unavailable)
            let isKeyring1Normal = !isKeyring1SelectedElsewhere && !isKeyring1Unavailable
            let isKeyring2Normal = !isKeyring2SelectedElsewhere && !isKeyring2Unavailable
            
            if isKeyring1Normal != isKeyring2Normal {
                return isKeyring1Normal
            }
            
            // 3순위: 다른 위치 장착 vs unavailable (다른 위치 장착이 먼저)
            if isKeyring1SelectedElsewhere != isKeyring2SelectedElsewhere {
                return isKeyring1SelectedElsewhere // elsewhere를 앞으로
            }
            
            // 4순위: unavailable 키링들 (맨 뒤)
            if isKeyring1Unavailable != isKeyring2Unavailable {
                return isKeyring2Unavailable // unavailable을 맨 뒤로
            }
            
            // 같은 그룹 내에서는 원래 순서 유지 (viewModel.keyringSorting 결과)
            guard let index1 = keyring.firstIndex(of: keyring1),
                  let index2 = keyring.firstIndex(of: keyring2) else {
                return false
            }
            return index1 < index2
        }
    }
}
