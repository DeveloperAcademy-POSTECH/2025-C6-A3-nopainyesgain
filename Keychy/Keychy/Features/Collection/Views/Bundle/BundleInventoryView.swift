//
//  BundleInventoryView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import SwiftUI

struct BundleInventoryView: View {
    //TODO: 라우터 어떻게 하는지 물어봐야 함!
    @Bindable var router: NavigationRouter<HomeRoute>
    
    @State var viewModel: CollectionViewModel

    let columns: [GridItem] = [
        // GridItem의 Spacing은 horizontal 간격
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13)
    ]
    
    var body: some View {
        VStack {
            bundleGrid
        }
        .padding(.horizontal, 16)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("뭉치함")
        .scrollIndicators(.hidden)
    }
}

//MARK: - 툴바
extension BundleInventoryView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
            }
        }
    }
    
    private var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("+") {
                router.push(.bundleSelectBackgroundView)
            }
        }
    }
}


//MARK: - 그리드 뷰
extension BundleInventoryView {
    private var bundleGrid: some View {
        ScrollView {
            //LazyVGrid의 spacing은 vertical 간격
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(viewModel.sortedBundles, id: \.self) { bundle in
                    Button {
                        router.push(.bundleDetailView)
                    } label: {
                        KeyringBundleItem(bundle: bundle)
                    }

                }

            }
        }
    }
}

#Preview {
    BundleInventoryView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
