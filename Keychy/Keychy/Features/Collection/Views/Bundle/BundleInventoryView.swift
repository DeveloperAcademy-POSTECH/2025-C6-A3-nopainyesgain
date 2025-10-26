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
            headerSection
            bundleGrid
        }
        .padding(.horizontal, 16)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .scrollIndicators(.hidden)
    }
}

//MARK: - 헤더뷰
extension BundleInventoryView {
    private var headerSection: some View {
        HStack {
            Spacer()
            Button {
                router.push(.BundleCreateView)
            } label: {
                Image(systemName: "plus")
                    .padding(10.25)
                    .background(
                        Circle()
                            .glassEffect(.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .overlay(
            Text("뭉치 보관함")
                .font(.title2)
                .bold()
        )
    }
}

//MARK: - 그리드 뷰
extension BundleInventoryView {
    private var bundleGrid: some View {
        ScrollView {
            //LazyVGrid의 spacing은 vertical 간격
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(viewModel.keyringBundle, id: \.self) { bundle in
                    Button {
                        router.push(.BundleDetailView)
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
