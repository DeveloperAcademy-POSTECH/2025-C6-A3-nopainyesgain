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
    
    /// "키치 배경"을 맨 앞으로 정렬
    private var sortedBackgrounds: [BackgroundViewData] {
        viewModel.backgroundViewData.sorted { bg1, bg2 in
            let isKeychy1 = bg1.background.backgroundName == "키치 배경"
            let isKeychy2 = bg2.background.backgroundName == "키치 배경"
            
            if isKeychy1 && !isKeychy2 {
                return true  // bg1이 앞으로
            } else if !isKeychy1 && isKeychy2 {
                return false  // bg2가 앞으로
            } else {
                return false  // 순서 유지
            }
        }
    }
    
    var body: some View {
        SelectionGridSheet(
            items: sortedBackgrounds,
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
