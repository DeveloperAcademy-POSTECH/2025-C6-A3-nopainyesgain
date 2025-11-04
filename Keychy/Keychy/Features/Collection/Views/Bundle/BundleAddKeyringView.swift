//
//  BundleAddKeyringView.swift
//  Keychy
//
//  Created by 김서현 on 10/28/25.
//

import SwiftUI
import SpriteKit
import NukeUI

struct BundleAddKeyringView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel

    @State private var showSelectKeyringSheet: Bool = false
    /// [index: Keyring]으로 몇 번째 인덱스(버튼 위치)에 어떤 키링이 있는지 저장합니다.
    @State private var selectedKeyrings: [Int: Keyring] = [:]
    @State private var selectedPosition: Int = 0
    @State private var carabinerScene: CarabinerScene?
    @State private var isSceneReady: Bool = false
    /// 키링이 걸려있는 부분의 버튼이 눌렸는지 확인하는 변수입니다.
    @State private var isDeleteButtonSelected: Bool = false

    var body: some View {
        ZStack {
            // 씬 프리뷰 (항상 표시)
            sceneDisplayView

            // 키링 선택 시트
            if showSelectKeyringSheet {
                keyringSelectionSheet
            }
        }
        .background(backgroundImage)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
        .onAppear {
            fetchUserData()
            createCarabinerScene()
        }
        .onDisappear {
            resetSelection()
        }
        .onChange(of: selectedKeyrings) { _, _ in
            updateCarabinerSceneWithKeyrings()
        }
    }
    
    // 선택 초기화
    private func resetSelection() {
        selectedKeyrings.removeAll()
        selectedPosition = 0
        isDeleteButtonSelected = false
        showSelectKeyringSheet = false
        isSceneReady = false
        carabinerScene = nil
    }
}

// MARK: - 배경 이미지
extension BundleAddKeyringView {
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
}

// MARK: - 씬 표시
extension BundleAddKeyringView {
    private var sceneDisplayView: some View {
        VStack {
            ZStack {
                if let scene = carabinerScene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // 버튼 오버레이 - 씬이 준비된 후에만 표시
                    if isSceneReady,
                       let carabiner = viewModel.selectedCarabiner,
                       let carabinerFrame = scene.getCarabinerFrame() {
                        buttonOverlaysView(
                            carabiner: carabiner,
                            carabinerFrame: carabinerFrame
                        )
                    }
                } else {
                    ProgressView()
                }
            }
            Spacer()
        }
    }

    private func buttonOverlaysView(
        carabiner: Carabiner,
        carabinerFrame: CGRect
    ) -> some View {
        ZStack {
            ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
                keyringPositionButton(
                    at: index,
                    carabiner: carabiner,
                    carabinerFrame: carabinerFrame
                )
            }
        }
    }

    private func keyringPositionButton(
        at index: Int,
        carabiner: Carabiner,
        carabinerFrame: CGRect
    ) -> some View {
        let x = carabinerFrame.origin.x + (carabinerFrame.width * carabiner.keyringXPosition[index])
        // Y 좌표: SpriteKit 비율(0=아래, 1=위)을 SwiftUI 비율(0=위, 1=아래)로 변환
        let yRatio = 1.0 - carabiner.keyringYPosition[index]
        let y = carabinerFrame.origin.y + (carabinerFrame.height * yRatio)

        return CarabinerAddKeyringButton(
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
        .position(x: x, y: y)
        .overlay(alignment: .top) {
            if isDeleteButtonSelected && selectedPosition == index && selectedKeyrings[index] != nil {
                editKeyringCapsuleButton()
                    .position(x: x, y: y - 49)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.spring, value: isDeleteButtonSelected)
            }
        }
    }

    private func editKeyringCapsuleButton() -> some View {
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
            Divider()
                .frame(height: 20)
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

// MARK: - 툴바
extension BundleAddKeyringView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
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
                prepareSceneForPreview()
                router.push(.bundleNameInputView)
            }
        }
    }
}

// MARK: - 키링 선택 시트
extension BundleAddKeyringView {
    private var keyringSelectionSheet: some View {
        VStack {
            sheetHeader
            keyringGridView
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20))
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(.white100)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .transition(.move(edge: .bottom))
        .zIndex(2)
    }

    private var sheetHeader: some View {
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
    }

    private var keyringGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(viewModel.keyring, id: \.self) { keyring in
                    keyringCell(keyring: keyring)
                }
            }
        }
    }

    private func keyringCell(keyring: Keyring) -> some View {
        Button(action: {
            selectedKeyrings[selectedPosition] = keyring
            withAnimation(.easeInOut) {
                showSelectKeyringSheet = false
            }
        }) {
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
}

// MARK: - 데이터 로드
extension BundleAddKeyringView {
    private func fetchUserData() {
        let uid = UserManager.shared.userUID
        fetchUserCategories(uid: uid) {
            fetchUserKeyrings(uid: uid)
        }
    }

    private func fetchUserKeyrings(uid: String) {
        viewModel.fetchUserKeyrings(uid: uid) { success in
            print("키링 로드: \(success ? "완료" : "실패"), 개수: \(viewModel.keyring.count)")
        }
    }

    private func fetchUserCategories(uid: String, completion: @escaping () -> Void) {
        viewModel.fetchUserCollectionData(uid: uid) { success in
            print("정보 로드: \(success ? "완료" : "실패")")
            completion()
        }
    }
}

// MARK: - 씬 생성 및 관리
extension BundleAddKeyringView {
    private func createCarabinerScene() {
        guard let carabiner = viewModel.selectedCarabiner,
              carabiner.carabinerImage.count > 2 else {
            return
        }

        let backImageURL = carabiner.carabinerImage[1]
        let frontImageURL = carabiner.carabinerImage[2]

        let defaultSize = CGSize(width: 393, height: 852)

        Task {
            do {
                async let backImage = StorageManager.shared.getImage(path: backImageURL)
                async let frontImage = StorageManager.shared.getImage(path: frontImageURL)

                let loadedBackImage = try await backImage
                let loadedFrontImage = try await frontImage

                await MainActor.run {
                    let scene = CarabinerScene(
                        carabiner: carabiner,
                        carabinerImage: loadedBackImage,
                        ringType: .basic,
                        chainType: .basic,
                        bodyType: .basic,
                        bodyImages: [],
                        targetSize: defaultSize,
                        screenWidth: defaultSize.width,
                        zoomScale: 1.0,
                        isPhysicsEnabled: false
                    )
                    scene.carabinerFrontImage = loadedFrontImage
                    scene.scaleMode = .resizeFill
                    scene.onSceneReady = {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            self.isSceneReady = true
                        }
                    }
                    self.carabinerScene = scene
                }
            } catch {
                print("카라비너 이미지 로드 실패: \(error)")
            }
        }
    }

    private func updateCarabinerSceneWithKeyrings() {
        guard let scene = carabinerScene,
              let carabiner = viewModel.selectedCarabiner else {
            return
        }

        var keyringData: [(index: Int, keyring: Keyring)] = []
        for index in 0..<carabiner.maxKeyringCount {
            if let keyring = selectedKeyrings[index] {
                keyringData.append((index: index, keyring: keyring))
            }
        }

        scene.keyrings.forEach { $0.removeFromParent() }
        scene.keyrings.removeAll()

        guard !keyringData.isEmpty else { return }

        loadKeyringImages(keyringData: keyringData) { loadedImages in
            guard let scene = self.carabinerScene,
                  let carabinerNode = scene.carabinerNode else {
                return
            }

            DispatchQueue.main.async {
                for (arrayIndex, (keyringIndex, _)) in keyringData.enumerated() {
                    guard arrayIndex < loadedImages.count else { continue }

                    let bodyImage = loadedImages[arrayIndex]
                    let nx = scene.getKeyringXPosition(for: keyringIndex)
                    let ny = scene.getKeyringYPosition(for: keyringIndex)
                    let carabinerSize = carabinerNode.size
                    let xOffset = (nx - 0.5) * carabinerSize.width
                    let yOffset = (ny - 0.5) * carabinerSize.height

                    scene.setupKeyringNode(
                        bodyImage: bodyImage,
                        position: CGPoint(x: xOffset, y: yOffset),
                        parent: carabinerNode,
                        index: keyringIndex
                    ) { createdKeyring in
                        scene.keyrings.append(createdKeyring)
                    }
                }
            }
        }
    }

    private func loadKeyringImages(
        keyringData: [(index: Int, keyring: Keyring)],
        completion: @escaping ([UIImage]) -> Void
    ) {
        Task {
            var loadedImages: [UIImage] = []

            for (_, keyring) in keyringData {
                do {
                    let image = try await StorageManager.shared.getImage(path: keyring.bodyImage)
                    loadedImages.append(image)
                } catch {
                    print("키링 이미지 로드 실패: \(keyring.bodyImage), 에러: \(error)")
                }
            }

            await MainActor.run {
                completion(loadedImages)
            }
        }
    }

    private func prepareSceneForPreview() {
        guard let scene = carabinerScene else { return }

        viewModel.selectedKeyringsForBundle = selectedKeyrings
        cleanupDuplicateKeyrings(in: scene)

        scene.physicsWorld.speed = 0
        scene.physicsWorld.gravity = .zero

        for keyring in scene.keyrings {
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

    private func cleanupDuplicateKeyrings(in scene: CarabinerScene) {
        guard let carabinerNode = scene.carabinerNode else { return }

        var keyringNodes: [String: [SKNode]] = [:]

        carabinerNode.enumerateChildNodes(withName: "keyring_*") { node, _ in
            if let name = node.name {
                keyringNodes[name, default: []].append(node)
            }
        }

        for (_, nodes) in keyringNodes where nodes.count > 1 {
            nodes.dropFirst().forEach { $0.removeFromParent() }
        }

        scene.keyrings = scene.keyrings.filter { $0.parent != nil }
    }
}

#Preview {
    BundleAddKeyringView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
