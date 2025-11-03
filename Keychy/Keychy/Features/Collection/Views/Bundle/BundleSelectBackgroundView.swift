//
//  BundleSelectBackgroundView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI

struct BundleSelectBackgroundView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    
    @State var viewModel: CollectionViewModel
    @State var isShowingDetailView: Bool = false
    
    let columns: [GridItem] = [
        // GridItem의 Spacing은 horizontal 간격
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13)
    ]
    
    var body: some View {
        selectBackgroundGrid
            .padding(.horizontal, 20)
            .toolbar(.hidden, for: .tabBar)
            .scrollIndicators(.hidden)
            .navigationTitle("배경")
            .task {
                await viewModel.loadBackgroundsAndCarabiners()
            }
    }
}

//MARK: - 그리드 뷰
extension BundleSelectBackgroundView {
    private var selectBackgroundGrid: some View {
        ScrollView {
            //LazyVGrid의 spacing은 vertical 간격
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(viewModel.backgroundViewData, id: \.id) { bg in
                    Button {
                        viewModel.selectedBackground = bg.background
                        router.push(.bundleSelectCarabinerView)
                    } label: {
                        SelectBackgroundGridItem(background: bg)
                    }
                }
                
            }
        }
    }
}

#Preview {
    BundleSelectBackgroundView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
