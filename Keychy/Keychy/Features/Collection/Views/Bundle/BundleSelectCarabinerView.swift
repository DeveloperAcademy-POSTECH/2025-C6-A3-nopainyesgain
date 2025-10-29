//
//  BundleSelectCarabinerView.swift
//  Keychy
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI

struct BundleSelectCarabinerView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                CarabinerImageView
                    .frame(width: geo.size.width * 0.5)
                Spacer()
                SelectCarabinerbottomSection
            }
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                backToolbarItem
                nextToolbarItem
            }
            .background(
                // 배경화면 이미지
                Image(.cherries)
                    .resizable()
                    .blur(radius: 10)
                    .scaledToFill()
            )
        }
    }
}

//MARK: - 툴바
extension BundleSelectCarabinerView {
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
            Button("다음") {
                router.push(.bundleAddKeyringView)
            }
        }
    }
}

//MARK: - 카라비너 뷰
extension BundleSelectCarabinerView {
    private var CarabinerImageView: some View {
        VStack {
            // 카라비너 이미지
            Image(.basicRing)
                .resizable()
                .scaledToFit()
                .overlay {
                    if let carabiner = viewModel.selectedCarabiner {
                        GeometryReader { geo in
                            ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
                                CarabinerAddKeyringButton()
                                    .position(
                                        x: geo.size.width * carabiner.keyringXPosition[index],
                                        y: geo.size.height * carabiner.keyringYPosition[index]
                                    )
                            }
                        }
                    }
                }
        }
    }
}

//MARK: - 하단 카라비너 선택 뷰
extension BundleSelectCarabinerView {
    private var SelectCarabinerbottomSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("카라비너")
                Spacer()
            }
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(viewModel.carabiner, id: \.self) { cb in
                        Button {
                            viewModel.selectedCarabiner = cb
                        } label: {
                            CarabinerItemTile(isSelected: viewModel.selectedCarabiner == cb, carabiner: cb)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 25)
        .padding(.horizontal, 16)
        .padding(.bottom, 115)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                topTrailingRadius: 20
            )
            .fill(Color.white.opacity(0.8))
            .shadow(radius: 10)
        )
    }
}

#Preview {
    BundleSelectCarabinerView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
