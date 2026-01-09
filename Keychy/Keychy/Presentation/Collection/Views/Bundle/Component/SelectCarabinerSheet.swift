//
//  SelectCarabinerSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/14/25.
//

import SwiftUI

struct SelectCarabinerSheet: View {
    let viewModel: CollectionViewModel
    let selectedCarabiner: CarabinerViewData?
    let onCarabinerTap: (CarabinerViewData) -> Void
    
    /// "키치 카라비너"를 맨 앞으로 정렬
    private var sortedCarabiners: [CarabinerViewData] {
        viewModel.carabinerViewData.sorted { cb1, cb2 in
            let isKeychy1 = cb1.carabiner.carabinerName == "키치 카라비너"
            let isKeychy2 = cb2.carabiner.carabinerName == "키치 카라비너"
            
            if isKeychy1 && !isKeychy2 {
                return true  // cb1이 앞으로
            } else if !isKeychy1 && isKeychy2 {
                return false  // cb2가 앞으로
            } else {
                return false  // 순서 유지
            }
        }
    }
    
    var body: some View {
        SelectionGridSheet(
            items: sortedCarabiners,
            selectedItem: selectedCarabiner,
            onItemTap: { carabiner in
                onCarabinerTap(carabiner)
                
                // 무료 카라비너인 경우만 바로 추가
                if !carabiner.isOwned && carabiner.carabiner.isFree {
                    Task {
                        await viewModel.addCarabinerToUser(carabinerName: carabiner.carabiner.carabinerName, userManager: UserManager.shared)
                    }
                }
            },
            gridItemView: { carabiner, isSelected in
                SelectCarabinerGridItem(
                    isSelected: isSelected,
                    carabiner: carabiner
                )
            }
        )
    }
}
