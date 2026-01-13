//
//  SelectBackgroundSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/14/25.
//

import SwiftUI

struct SelectBackgroundSheet: View {
    let viewModel: BundleViewModel
    let selectedBG: BackgroundViewData?
    let onBackgroundTap: (BackgroundViewData) -> Void
    
    /// 3열 그리드 컬럼 설정
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
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
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(sortedBackgrounds) { bg in
                BackgroundSelectableCell(background: bg, isSelected: (bg == selectedBG))
                    .onTapGesture {
                        onBackgroundTap(bg)
                        
                        // 무료이고, 유저가 보유x인 경우에만 바로 추가
                        if !bg.isOwned && bg.background.isFree {
                            Task {
                                await viewModel.addBackgroundToUser(backgroundName: bg.background.backgroundName, userManager: UserManager.shared)
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
    }
}
