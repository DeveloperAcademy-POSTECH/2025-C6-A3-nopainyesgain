//
//  BundleAddKeyringView.swift
//  Keychy
//
//  Created by 김서현 on 10/28/25.
//

import SwiftUI
import SpriteKit
import NukeUI

/// 번들에 키링을 추가하는 뷰
struct BundleAddKeyringView: View {
    // MARK: - Properties

    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel

    @State private var showSelectKeyringSheet: Bool = false
    @State private var selectedKeyrings: [Int: Keyring] = [:]
    @State private var selectedPosition: Int = 0
    @State private var carabinerScene: CarabinerScene?
    @State private var isSceneReady: Bool = false
    @State private var isDeleteButtonSelected: Bool = false

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                sceneView(geometry: geometry)

                if showSelectKeyringSheet {
                    keyringSelectionSheet(height: geometry.size.height * 0.5)
                }
            }
            .ignoresSafeArea()
            .background(backgroundImage)
            .onAppear {
                setupScene(geometry: geometry)
            }
            .onChange(of: selectedKeyrings) { _, _ in
                updateKeyringsInScene()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backButton
            nextButton
        }
    }
}

// MARK: - View Components

extension BundleAddKeyringView {
    /// 배경 이미지
    private var backgroundImage: some View {
        Group {
            if let background = viewModel.selectedBackground {
                LazyImage(url: URL(string: background.backgroundImage)) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else if state.isLoading {
                        Color.clear
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    /// 씬 뷰
    private func sceneView(geometry: GeometryProxy) -> some View {
        VStack {
            ZStack {
                if let scene = carabinerScene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .background(.clear)

                    if isSceneReady, let carabiner = viewModel.selectedCarabiner,
                       let frame = scene.getCarabinerFrame() {
                        keyringButtons(carabiner: carabiner, frame: frame)
                    }
                } else {
                    ProgressView()
                }
            }
            Spacer()
        }
    }

    /// 키링 추가 버튼들
    private func keyringButtons(carabiner: Carabiner, frame: CGRect) -> some View {
        ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
            let position = buttonPosition(index: index, carabiner: carabiner, frame: frame)

            CarabinerAddKeyringButton(
                isSelected: selectedPosition == index,
                hasKeyring: selectedKeyrings[index] != nil,
                action: {
                    selectedPosition = index
                    withAnimation(.easeInOut) {
                        showSelectKeyringSheet = true
                    }
                },
                secondAction: {
                    selectedPosition = index
                    isDeleteButtonSelected = true
                }
            )
            .position(position)
            .overlay(alignment: .top) {
                if isDeleteButtonSelected && selectedPosition == index && selectedKeyrings[index] != nil {
                    deleteButton()
                        .position(x: position.x, y: position.y - 49)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.spring, value: isDeleteButtonSelected)
                }
            }
        }
    }

    /// 키링 선택 시트
    private func keyringSelectionSheet(height: CGFloat) -> some View {
        VStack {
            HStack {
                Button {
                    withAnimation(.easeInOut) {
                        showSelectKeyringSheet = false
                    }
                } label: {
                    Image(systemName: "xmark")
                }
                Spacer()
                Text("키링 선택")
                Spacer()
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.keyring, id: \.self) { keyring in
                        keyringCell(keyring: keyring)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20))
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(.white100)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom))
        .zIndex(2)
    }

    /// 키링 셀
    private func keyringCell(keyring: Keyring) -> some View {
        Button {
            selectedKeyrings[selectedPosition] = keyring
            withAnimation(.easeInOut) {
                showSelectKeyringSheet = false
            }
        } label: {
            VStack {
                CollectionCellView(keyring: keyring)
                    .frame(width: 175, height: 223)
                    .cornerRadius(10)
                    .padding(.bottom, 10)

                Text("\(keyring.name) 키링")
                    .typography(.suit14SB18)
                    .foregroundStyle(.black100)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 175, height: 261)
        .disabled(keyring.status == .packaged || keyring.status == .published)
    }

    /// 삭제 버튼
    private func deleteButton() -> some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                isDeleteButtonSelected = false
            } label: {
                Text("취소")
                    .typography(.suit16M)
                    .foregroundStyle(.black100)
            }
            Spacer()
            Divider().frame(height: 20)
            Spacer()
            Button {
                selectedKeyrings[selectedPosition] = nil
                isDeleteButtonSelected = false
            } label: {
                Text("삭제")
                    .typography(.suit16M)
                    .foregroundStyle(.primaryRed)
            }
            Spacer()
        }
        .frame(width: 129, height: 44)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Toolbar

extension BundleAddKeyringView {
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }

    private var nextButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("다음") {
                saveScene()
                router.push(.bundleNameInputView)
            }
        }
    }
}

// MARK: - Scene Management

extension BundleAddKeyringView {
    /// 초기 씬 설정
    private func setupScene(geometry: GeometryProxy) {
        fetchData()

        // TODO: 임시 - 첫 번째 카라비너 자동 선택
        if !viewModel.carabiners.isEmpty {
            viewModel.selectedCarabiner = viewModel.carabiners[0]
        }

        createScene(size: geometry.size, screenWidth: geometry.size.width)
    }

    /// 씬 생성
    private func createScene(size: CGSize, screenWidth: CGFloat) {
        guard let carabiner = viewModel.selectedCarabiner,
              let imageURL = carabiner.carabinerImage[safe: 1] else {
            return
        }

        isSceneReady = false

        Task {
            guard let image = try? await StorageManager.shared.getImage(path: imageURL) else {
                print("카라비너 이미지 로드 실패")
                return
            }

            await MainActor.run {
                let scene = CarabinerScene(
                    carabiner: carabiner,
                    carabinerImage: image,
                    ringType: .basic,
                    chainType: .basic,
                    bodyType: .basic,
                    bodyImages: [],
                    targetSize: size,
                    screenWidth: screenWidth,
                    zoomScale: 1.0,
                    isPhysicsEnabled: false
                )

                scene.scaleMode = .resizeFill
                scene.onSceneReady = {
                    DispatchQueue.main.async {
                        self.isSceneReady = true
                    }
                }

                self.carabinerScene = scene
            }
        }
    }

    /// 키링 업데이트
    private func updateKeyringsInScene() {
        guard let scene = carabinerScene,
              let carabiner = viewModel.selectedCarabiner else {
            return
        }

        // 기존 키링 제거
        scene.keyrings.forEach { $0.removeFromParent() }
        scene.keyrings.removeAll()

        // 선택된 키링 수집
        let keyringData = selectedKeyrings.compactMap { index, keyring in
            index < carabiner.maxKeyringCount ? (index, keyring) : nil
        }

        guard !keyringData.isEmpty else { return }

        // 키링 추가
        loadAndAddKeyrings(keyringData: keyringData, scene: scene)
    }

    /// 키링 로드 및 추가
    private func loadAndAddKeyrings(keyringData: [(Int, Keyring)], scene: CarabinerScene) {
        Task {
            var images: [UIImage] = []

            for (_, keyring) in keyringData {
                if let image = try? await StorageManager.shared.getImage(path: keyring.bodyImage) {
                    images.append(image)
                }
            }

            await MainActor.run {
                guard let carabinerNode = scene.carabinerNode else { return }

                for (i, (index, _)) in keyringData.enumerated() where i < images.count {
                    let position = keyringPosition(index: index, scene: scene, size: carabinerNode.frame.size)

                    scene.setupKeyringNode(
                        bodyImage: images[i],
                        position: position,
                        parent: carabinerNode,
                        index: index
                    ) { keyring in
                        scene.keyrings.append(keyring)
                    }
                }
            }
        }
    }

    /// 씬 저장
    private func saveScene() {
        guard let scene = carabinerScene else { return }

        viewModel.selectedKeyringsForBundle = selectedKeyrings

        // 물리 시뮬레이션 비활성화
        scene.physicsWorld.speed = 0
        scene.physicsWorld.gravity = .zero

        // 모든 노드 고정
        scene.keyrings.forEach { keyring in
            keyring.enumerateChildNodes(withName: "//*") { node, _ in
                node.physicsBody?.isDynamic = false
                node.physicsBody?.affectedByGravity = false
                node.removeAllActions()
            }
        }

        scene.carabinerNode?.physicsBody?.isDynamic = false
        scene.carabinerNode?.physicsBody?.affectedByGravity = false
        scene.carabinerNode?.removeAllActions()

        viewModel.bundlePreviewScene = scene
    }
}

// MARK: - Data Fetching

extension BundleAddKeyringView {
    private func fetchData() {
        let uid = UserManager.shared.userUID

        viewModel.fetchUserCollectionData(uid: uid) { success in
            if success {
                viewModel.fetchUserKeyrings(uid: uid) { _ in }
            }
        }
    }
}

// MARK: - Helper Methods

extension BundleAddKeyringView {
    /// 버튼 위치 계산
    private func buttonPosition(index: Int, carabiner: Carabiner, frame: CGRect) -> CGPoint {
        let x = frame.origin.x + (frame.width * carabiner.keyringXPosition[index])
        let yRatio = 1.0 - carabiner.keyringYPosition[index]
        let y = frame.origin.y + (frame.height * yRatio)
        return CGPoint(x: x, y: y)
    }

    /// 키링 위치 계산
    private func keyringPosition(index: Int, scene: CarabinerScene, size: CGSize) -> CGPoint {
        let nx = scene.getKeyringXPosition(for: index)
        let ny = scene.getKeyringYPosition(for: index)
        return CGPoint(x: (nx - 0.5) * size.width, y: (ny - 0.5) * size.height)
    }
}

#Preview {
    BundleAddKeyringView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
