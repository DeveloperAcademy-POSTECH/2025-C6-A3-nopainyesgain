//
//  BundleSelectCarabinerView.swift
//  Keychy
//
//  Created by 김서현 on 10/26/25.
//

import SwiftUI
import NukeUI
import SpriteKit

struct BundleSelectCarabinerView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel

    @State private var carabinerScene: CarabinerPreviewScene?

    var body: some View {
        ZStack(alignment: .bottom) {
            // 씬 프리뷰 (항상 표시)
            if let carabinerScene {
                SpriteView(scene: carabinerScene, options: [.allowsTransparency])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // 하단 선택 UI (항상 하단에 배치)
            carabinerSelectionView
        }
        .background(backgroundImage)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    // 뒤로 가기 시 초기화
                    resetSelection()
                    router.pop()
                }) {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("다음") {
                    router.push(.bundleAddKeyringView)
                }
                .disabled(viewModel.selectedCarabiner == nil)
            }
        }
        .onAppear {
            // 빈 씬 먼저 생성
            createEmptyScene()
            // 카라비너 목록 로드
            viewModel.fetchAllCarabiners { success in
                print("카라비너 목록 로드: \(success), 개수: \(viewModel.carabinerViewData.count)")
            }
        }
        .onDisappear {
            // 화면을 떠날 때 초기화
            resetSelection()
        }
        .onChange(of: viewModel.selectedCarabiner) { _, newCarabiner in
            // 카라비너 선택 시 씬에 적용
            if let carabiner = newCarabiner {
                updateSceneWithCarabiner(carabiner)
            }
        }
    }

    // MARK: - 배경 이미지
    private var backgroundImage: some View {
        Group {
            if let background = viewModel.selectedBackground {
                LazyImage(url: URL(string: background.backgroundImage)) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 하단 카라비너 선택 UI
    private var carabinerSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("카라비너")

            if viewModel.carabinerViewData.isEmpty {
                // 데이터가 없을 때 로딩 표시
                HStack {
                    ProgressView()
                    Text("카라비너 로딩 중...")
                        .foregroundColor(.gray)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.carabinerViewData, id: \.id) { cb in
                            Button {
                                viewModel.selectedCarabiner = cb.carabiner
                            } label: {
                                CarabinerItemTile(
                                    isSelected: viewModel.selectedCarabiner == cb.carabiner,
                                    carabiner: cb
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 25)
        .padding(.horizontal, 16)
        .padding(.bottom, 115)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .fill(Color.white.opacity(0.8))
                .shadow(radius: 10)
        )
    }

    // MARK: - 씬 생성

    /// 빈 씬 생성 (초기 상태)
    private func createEmptyScene() {
        let defaultSize = CGSize(width: 393, height: 852)
        let scene = CarabinerPreviewScene(targetSize: defaultSize, carabinerImage: nil)
        scene.scaleMode = .resizeFill
        self.carabinerScene = scene
    }

    /// 카라비너 선택 시 씬 업데이트
    private func updateSceneWithCarabiner(_ carabiner: Carabiner) {
        guard let imageURL = carabiner.carabinerImage.first else { return }

        Task {
            guard let image = try? await StorageManager.shared.getImage(path: imageURL) else { return }

            await MainActor.run {
                // 기존 씬에 이미지와 키링 위치 업데이트
                carabinerScene?.updateCarabinerImage(image)
                carabinerScene?.updateKeyringPositions(
                    x: carabiner.keyringXPosition.map { CGFloat($0) },
                    y: carabiner.keyringYPosition.map { CGFloat($0) }
                )
            }
        }
    }

    /// 선택 초기화
    private func resetSelection() {
        // 카라비너 선택 초기화
        viewModel.selectedCarabiner = nil
        // 씬을 빈 씬으로 초기화
        createEmptyScene()
    }
}
