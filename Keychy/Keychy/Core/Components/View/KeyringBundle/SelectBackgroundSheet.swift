//
//  SelectBackgroundSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/14/25.
//

import SwiftUI

struct SelectBackgroundSheet: View {
    let viewModel: CollectionViewModel
    let selectedBG: BackgroundViewData?
    let onBackgroundTap: (BackgroundViewData) -> Void
    
    var body: some View {
        SelectionGridSheet(
            items: viewModel.backgroundViewData,
            selectedItem: selectedBG,
            onItemTap: { bg in
                onBackgroundTap(bg)
                
                // 무료이고, 유저가 보유x인 경우만 바로 추가
                if !bg.isOwned && bg.background.isFree {
                    Task {
                        await viewModel.addBackgroundToUser(backgroundName: bg.background.backgroundName, userManager: UserManager.shared)
                    }
                }
            },
            gridItemView: { bg, isSelected in
                SelectBackgroundGridItem(
                    background: bg,
                    isSelected: isSelected
                )
            }
        )
    }
}
