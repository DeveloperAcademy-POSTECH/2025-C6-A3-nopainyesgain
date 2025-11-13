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

    @State private var carabinerImage: UIImage?
    @State private var isLoading: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 카라비너 이미지 프리뷰
                VStack {
                    if let image = carabinerImage {
                        ZStack(alignment: .top) {
                            // 이미지
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()

                            // 키링 포인트 표시 (이미지 실제 표시 Rect 기준)
                            if let carabiner = viewModel.selectedCarabiner {
                                let imageRect = scaledToFitRect(
                                    containerSize: geometry.size,
                                    imageSize: geometry.size
                                )
                                keyringPointsOverlay(
                                    carabiner: carabiner,
                                    imageRect: imageRect
                                )
                            }
                        }
                    } else if isLoading {
                        ProgressView()
                            .padding(.top, 60)
                    }
                    Spacer()
                }
                .padding(.top, 60)

                // 하단 선택 UI (항상 하단에 배치)
                carabinerSelectionView(geo: geometry)
            }
            .background(backgroundImage)
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
        .onAppear {
            // 카라비너 목록 로드
            viewModel.fetchAllCarabiners { success in
                print("카라비너 목록 로드: \(success), 개수: \(viewModel.carabinerViewData.count)")
            }
            // 초기 선택 상태가 있으면 이미지 로드
            if let carabiner = viewModel.selectedCarabiner {
                loadCarabinerImage(carabiner)
            }
        }
        .onChange(of: viewModel.selectedCarabiner) { _, newCarabiner in
            // 카라비너 선택 시 이미지 업데이트
            if let carabiner = newCarabiner {
                loadCarabinerImage(carabiner)
            } else {
                carabinerImage = nil
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
                    } else if state.isLoading {
                        Color.clear
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 하단 카라비너 선택 UI
    private func carabinerSelectionView(geo: GeometryProxy)-> some View {
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
                                SelectCarabinerGridItem(
                                    isSelected: viewModel.selectedCarabiner?.id == cb.carabiner.id,
                                    carabiner: cb,
                                    widthSize: geo.size.width
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

    // MARK: - 키링 포인트 오버레이

    /// 키링 포인트 표시 (이미지 실제 표시 Rect 기준)
    private func keyringPointsOverlay(carabiner: Carabiner, imageRect: CGRect) -> some View {
        ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
            // 정규화 좌표 → 이미지 Rect 내부 실제 좌표
            let x = carabiner.keyringXPosition[index] * imageRect.width
            let y = carabiner.keyringYPosition[index] * imageRect.height
            CarabinerAddKeyringButton(
                isSelected: false,
                action: {}
            )
            .position(x: x, y: y)
            .disabled(true)
        }
    }

    // MARK: - 이미지 로딩

    /// 카라비너 이미지 로드
    private func loadCarabinerImage(_ carabiner: Carabiner) {
        guard let imageURL = carabiner.carabinerImage.first else {
            carabinerImage = nil
            return
        }

        isLoading = true

        Task {
            guard let image = try? await StorageManager.shared.getImage(path: imageURL) else {
                await MainActor.run {
                    isLoading = false
                    carabinerImage = nil
                }
                return
            }

            await MainActor.run {
                self.carabinerImage = image
                self.isLoading = false
            }
        }
    }

    /// 선택 초기화
    private func resetSelection() {
        viewModel.selectedCarabiner = nil
        carabinerImage = nil
    }

    // MARK: - 유틸: scaledToFit 결과 Rect 계산
    /// 컨테이너 크기와 원본 이미지 크기를 받아 .scaledToFit으로 렌더링될 실제 Rect를 반환
    private func scaledToFitRect(containerSize: CGSize, imageSize: CGSize) -> CGRect {
        guard containerSize.width > 0, containerSize.height > 0,
              imageSize.width > 0, imageSize.height > 0 else {
            return .zero
        }

        let containerAspect = containerSize.width / containerSize.height
        let imageAspect = imageSize.width / imageSize.height

        var drawSize = CGSize.zero
        if imageAspect > containerAspect {
            // 가로가 꽉 참
            drawSize.width = containerSize.width
            drawSize.height = containerSize.width / imageAspect
        } else {
            // 세로가 꽉 참
            drawSize.height = containerSize.height
            drawSize.width = containerSize.height * imageAspect
        }

        let origin = CGPoint(
            x: (containerSize.width - drawSize.width) / 2,
            y: (containerSize.height - drawSize.height) / 2
        )

        return CGRect(origin: origin, size: drawSize)
    }
}

// MARK: - 툴바
extension BundleSelectCarabinerView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                // 뒤로 가기 시 초기화
                resetSelection()
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
            .disabled(viewModel.selectedCarabiner == nil)
        }
    }
}
