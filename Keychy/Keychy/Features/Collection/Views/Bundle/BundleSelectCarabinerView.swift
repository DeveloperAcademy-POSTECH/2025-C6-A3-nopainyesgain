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
    
    @State var backgroundImage: UIImage
    @State private var carabinerImage: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                // 카라비너의 사이즈는 화면 전체 높이의 1/2만 차지하도록 수정
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
                    if let selectedBackground = viewModel.selectedBackground {
                        Image(uiImage: viewModel.selectedBackgroundImage)
                            .resizable()
                            .blur(radius: 10)
                            .scaledToFill()
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .onAppear {
            viewModel.fetchAllCarabiners(uid: UserManager.shared.userUID) { success in
                if success {
                    print("카라비너 로드 완료 : \(viewModel.carabiners.count)")
                } else {
                    print("카라비너 로드 실패")
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
        VStack {
            // 카라비너 이미지
            Group {
                if let image = carabinerImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                        .scaleEffect(1.5)
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
                    ForEach(viewModel.carabiners, id: \.id) { cb in
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
