//
//  BundleSelectCarabinerView.swift
//  Keychy
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI
import NukeUI

struct BundleSelectCarabinerView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    @State var backgroundImage: String?
    @State private var carabinerImage: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                // 카라비너의 사이즈는 화면 전체 높이의 1/2만 차지하도록
                showSelectCarabinerView
                    .frame(width: geo.size.width * 0.5)
                Spacer()
                selectCarabinerbottomSection
            }
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                backToolbarItem
                nextToolbarItem
            }
            // 배경화면 이미지
            .background(
                Group {
                    if let background = viewModel.selectedBackground {
                        LazyImage(url: URL(string: background.backgroundImage)) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else if state.isLoading {
                                Color.clear
                            }
                        }
                    }
                }
                    .ignoresSafeArea()
            )
        }
        .task {
            viewModel.fetchAllCarabiners { success in
                if !success {
                    print("카라비너 데이터 로드 실패")
                }
            }
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

//MARK: - 선택한 카라비너 뷰
extension BundleSelectCarabinerView {
    private var showSelectCarabinerView: some View {
        VStack(spacing: 0) {
            // 카라비너 이미지
            Group {
                if let carabiner = viewModel.selectedCarabiner {
                    LazyImage(url: URL(string: carabiner.carabinerImage[0])) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200) // 최대 높이만 제한, 비율은 자유롭게
                        } else if state.isLoading {
                            ProgressView()
                                .frame(height: 200)
                        } else {
                            Color.clear
                                .frame(height: 200)
                        }
                    }
                }
            }
            // 카라비너 위 +버튼들 배치
                .overlay {
                    if let carabiner = viewModel.selectedCarabiner {
                        GeometryReader { geo in
                            ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
                                let x = geo.size.width * carabiner.keyringXPosition[index]
                                // Y 좌표: SpriteKit 비율(0=아래, 1=위)을 SwiftUI 비율(0=위, 1=아래)로 변환
                                let yRatio = 1.0 - carabiner.keyringYPosition[index] // 비율 뒤집기
                                let y = geo.size.height * yRatio
                                
                                CarabinerAddKeyringButton(
                                    isSelected: false,
                                    hasKeyring: false,
                                    action: {},
                                    secondAction: {}
                                )
                                .disabled(true)
                                .position(x: x, y: y)
                            }
                        }
                    }
                }
        }
    }
}

//MARK: - 하단 카라비너 선택 뷰
extension BundleSelectCarabinerView {
    private var selectCarabinerbottomSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("카라비너")
                Spacer()
            }
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(viewModel.carabinerViewData, id: \.id) { cb in
                        Button {
                            viewModel.selectedCarabiner = cb.carabiner
                        } label: {
                            CarabinerItemTile(isSelected: viewModel.selectedCarabiner == cb.carabiner, carabiner: cb)
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
