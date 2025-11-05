//
//  BundleSelectCarabinerView.swift
//  Keychy
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI
import Nuke
import NukeUI
import SpriteKit

struct BundleSelectCarabinerView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    // 상단 컨테이너 높이 비율 (보기 영역 확대)
    private let previewContainerHeightFactor: CGFloat = 0.8
    
    // Scene 보관 - BundleAddKeyringView와 동일한 씬 사용
    @State private var carabinerScene: CarabinerPreviewScene?
    @State private var isSceneReady: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    previewSceneView
                        .frame(
                            width: geo.size.width,
                            height: geo.size.height * previewContainerHeightFactor
                        )
                    Spacer()
                }
                selectCarabinerbottomSection
            }
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea()
            .toolbar {
                backToolbarItem
                nextToolbarItem
            }
            .background(backgroundLayer)
            .onAppear {
                let targetSize = CGSize(width: geo.size.width, height: geo.size.height * previewContainerHeightFactor)
                makeOrUpdateCarabinerScene(targetSize: targetSize, screenWidth: geo.size.width)
            }
            .onChange(of: viewModel.selectedCarabiner?.carabinerImage.first ?? "") { _, _ in
                let targetSize = CGSize(width: geo.size.width, height: geo.size.height * previewContainerHeightFactor)
                makeOrUpdateCarabinerScene(targetSize: targetSize, screenWidth: geo.size.width)
            }
            .onChange(of: geo.size) { _, newSize in
                let targetSize = CGSize(width: newSize.width, height: newSize.height * previewContainerHeightFactor)
                carabinerScene?.updateSize(targetSize)
            }
        }
        .task {
            viewModel.fetchAllCarabiners { success in
                if !success {
                    print("카라비너 데이터 로드 실패")
                }
            }
        }
    }
    
    private var previewSceneView: some View {
        ZStack {
            if let carabinerScene {
                SpriteView(scene: carabinerScene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            } else {
                ProgressView()
            }
        }
    }
}

// MARK: - 배경
extension BundleSelectCarabinerView {
    private var backgroundLayer: some View {
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
    }
}

// MARK: - 씬 생성 (BundleAddKeyringView와 동일한 방식)
extension BundleSelectCarabinerView {
    // CarabinerPreviewScene 생성 또는 업데이트
    private func makeOrUpdateCarabinerScene(targetSize: CGSize, screenWidth: CGFloat) {
        guard let carabiner = viewModel.selectedCarabiner else { return }
        
        // 이미지 URL 확인
        guard let backImageURL = carabiner.carabinerImage.first else { return }
        
        Task {
            do {
                // 이미지 로드
                let carabinerImage = try await StorageManager.shared.getImage(path: backImageURL)
                
                await MainActor.run {
                    // CarabinerPreviewScene 생성 (BundleAddKeyringView의 CarabinerScene과 동일한 크기 적용)
                    let scene = CarabinerPreviewScene(targetSize: targetSize, carabinerImage: carabinerImage)
                    scene.scaleMode = .resizeFill
                    
                    // 키링 포인트 업데이트
                    let xs = carabiner.keyringXPosition.map { CGFloat($0) }
                    let ys = carabiner.keyringYPosition.map { CGFloat($0) }
                    scene.updateKeyringPositions(x: xs, y: ys)
                    
                    self.carabinerScene = scene
                    self.isSceneReady = true
                }
            } catch {
                print("카라비너 이미지 로드 실패: \(error)")
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
