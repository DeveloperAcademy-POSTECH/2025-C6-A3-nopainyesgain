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
    }
}

//MARK: - 그리드 뷰
extension BundleSelectBackgroundView {
    private var selectBackgroundGrid: some View {
        ScrollView {
            //LazyVGrid의 spacing은 vertical 간격
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(viewModel.background, id: \.self) { bg in
                    Button {
                        viewModel.selectedBackground = bg
                        router.push(.bundleSelectCarabinerView)
                    } label: {
                        VStack(spacing: 10) {
                            selectBackgroundGridItem(background: bg)
                            Text(bg.backgroundName)
                                .typography(.suit14SB18)
                                .foregroundStyle(Color.black100)
                        }
                    }
                }
                
            }
        }
    }
    
    private func selectBackgroundGridItem(background: Background) -> some View {
        ZStack {
            Image(background.backgroundImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    VStack {
                        HStack {
                            //TODO: 유저가 보유한 background에 해당 bg가 포함되어 있는지 상태 확인하고 분기 처리 필요!
                            Image(.cherries)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .padding(EdgeInsets(top: 7, leading: 10, bottom: 0, trailing: 0))
                            Spacer()
                            Text("보유")
                                .typography(.suit13SB)
                                .foregroundStyle(Color.white100)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(
                                    UnevenRoundedRectangle(bottomLeadingRadius: 5, topTrailingRadius: 10)
                                        .fill(Color.black60)
                                )
                        }
                        Spacer()
                    }
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                )
        }
    }
}

#Preview {
    BundleSelectBackgroundView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
