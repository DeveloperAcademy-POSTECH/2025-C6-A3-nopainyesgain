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
    
    var body: some View {
        SelectionGridSheet(
            items: viewModel.carabinerViewData,
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
