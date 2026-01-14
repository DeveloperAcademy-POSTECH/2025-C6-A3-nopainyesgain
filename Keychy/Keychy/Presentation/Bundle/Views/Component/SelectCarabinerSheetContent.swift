//
//  SelectCarabinerSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/14/25.
//

import SwiftUI

struct SelectCarabinerSheet: View {
    let viewModel: BundleViewModel
    let selectedCarabiner: CarabinerViewData?
    let onCarabinerTap: (CarabinerViewData) -> Void
    
    /// 3열 그리드 컬럼 설정
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
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
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(sortedCarabiners) { cb in
                CarabinerSelectableCell(carabiner: cb, isSelected: (selectedCarabiner == cb))
                    .onTapGesture {
                        onCarabinerTap(cb)
                        
                        if !cb.isOwned && cb.carabiner.isFree {
                            Task {
                                await viewModel.addCarabinerToUser(carabinerName: cb.carabiner.carabinerName, userManager: UserManager.shared)
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
    }
}
