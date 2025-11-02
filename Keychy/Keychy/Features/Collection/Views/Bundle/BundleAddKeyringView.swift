//
//  BundleAddKeyringView.swift
//  Keychy
//
//  Created by 김서현 on 10/28/25.
//

import SwiftUI
import SpriteKit

struct BundleAddKeyringView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    @State var showSelectKeyringSheet: Bool = false
    /// [index: Keyring]으로 몇 번째 인덱스(버튼 위치)에 어떤 키링이 있는지 저장합니다.
    @State var selectedKeyrings: [Int: Keyring] = [:]
    @State var selectedPosition: Int = 0
    @State var carabinerScene: CarabinerScene?
    @State var isSceneReady: Bool = false
    @State var needsSceneUpdate: Bool = false
    /// 키링이 걸려있는 부분의 버튼이 눌렸는지 확인하는 변수입니다.
    @State var isDeleteButtonSelected: Bool = false
    
    let columns: [GridItem] = [
        // GridItem의 Spacing은 horizontal 간격
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 배경 이미지
                Image(.cherries)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .blur(radius: 20)
                
                keyringSceneView(geo: geo)
                
                if showSelectKeyringSheet {
                    keyringSelectScrollView
                        .frame(maxWidth: .infinity)
                    // 하단 뷰 사이즈는 전체 화면 높이의 1/2 채움
                        .frame(height: geo.size.height * 0.5)
                        .background(.white100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom))
                    // ZStack에서 순서 보장 (index가 2이므로 항상 맨 위에 쌓이는 것이 보장됨)
                        .zIndex(2)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                fetchUserData()
                //임시로 넣어둔 것
                viewModel.selectedCarabiner = viewModel.carabiners[0]
                let sceneSize = CGSize(width: geo.size.width, height: geo.size.height)
                makeOrUpdateCarabinerScene(
                    targetSize: sceneSize,
                    screenWidth: geo.size.width
                )
            }
            .onChange(of: selectedKeyrings) { oldValue, newValue in
                // selectedKeyrings이 변경될 때 씬 업데이트 플래그 설정
                needsSceneUpdate = true
            }
            .onChange(of: needsSceneUpdate) { oldValue, newValue in
                // needsSceneUpdate가 true가 되면 씬 업데이트
                if newValue {
                    updateCarabinerSceneWithKeyrings()
                    needsSceneUpdate = false
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
    }
    
    // MARK: - 사용자 데이터 로드
    private func fetchUserData() {
        let uid = "iX4yns1clYf9z8TS0Wv10k83pFw2"
        
        fetchUserCategories(uid: uid) {
            fetchUserKeyrings(uid: uid)
        }
    }
    
    // 키링 로드
    private func fetchUserKeyrings(uid: String) {
        viewModel.fetchUserKeyrings(uid: uid) { success in
            if success {
                print("키링 로드 완료: \(viewModel.keyring.count)개")
            } else {
                print("키링 로드 실패")
            }
        }
    }
    
    // 사용자 기반 데이터 로드
    private func fetchUserCategories(uid: String, completion: @escaping () -> Void) {
        viewModel.fetchUserCollectionData(uid: uid) { success in
            if success {
                print("정보 로드 완료")
            } else {
                print("정보 로드 실패")
            }
            completion()
        }
    }
}

// MARK: - 카라비너 + 키링 SpriteKit 씬 표시
extension BundleAddKeyringView {
    private func keyringSceneView(geo: GeometryProxy) -> some View {
        VStack {
            ZStack {
                if let scene = carabinerScene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .background(.clear)
                    
                    // 버튼 오버레이 - 씬이 준비된 후에만 표시
                    carabinerButtonOverlay(scene: scene)
                } else {
                    ProgressView()
                        .frame(width: geo.size.width * 0.5, height: geo.size.height * 0.5)
                }
            }
            Spacer()
        }
    }
    
    private func carabinerButtonOverlay(scene: CarabinerScene) -> some View {
        Group {
            if let carabiner = viewModel.selectedCarabiner, isSceneReady {
                if let carabinerFrame = scene.getCarabinerFrame() {
                    buttonOverlays(carabiner: carabiner, carabinerFrame: carabinerFrame)
                } else {
                    EmptyView()
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func buttonOverlays(carabiner: Carabiner, carabinerFrame: CGRect) -> some View {
        ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
            let x = carabinerFrame.origin.x + (carabinerFrame.width * carabiner.keyringXPosition[index])
            // Y 좌표: SpriteKit 비율(0=아래, 1=위)을 SwiftUI 비율(0=위, 1=아래)로 변환
            let yRatio = 1.0 - carabiner.keyringYPosition[index] // 비율 뒤집기
            let y = carabinerFrame.origin.y + (carabinerFrame.height * yRatio)
            
            CarabinerAddKeyringButton(
                isSelected: selectedPosition == index,
                hasKeyring: selectedKeyrings[index] != nil,
                action: {
                    // 키링 추가/교체 액션 (키링이 없거나, 이미 있는 키링을 교체하고 싶을 때)
                    selectedPosition = index
                    withAnimation(.easeInOut) {
                        showSelectKeyringSheet = true
                    }
                },
                secondAction: {
                    selectedPosition = index  // 선택된 위치도 설정
                    isDeleteButtonSelected = true
                }
            )
            .position(x: x, y: y)
            .overlay(alignment: .top) {
                if isDeleteButtonSelected && selectedPosition == index && selectedKeyrings[index] != nil {
                    editKeyringCapsuleButton()
                        .position(x: x, y: y - 49) // 버튼 위로 띄움
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.spring, value: isDeleteButtonSelected)
                }
            }
        }
    }
}

//MARK: - 툴바
extension BundleAddKeyringView {
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
                // 선택된 키링들을 ViewModel에 저장
                viewModel.selectedKeyringsForBundle = selectedKeyrings
                
                // 씬을 미리보기용으로 안정화 후 저장
                prepareSceneForPreview()
                
                router.push(.bundleNameInputView)
            }
        }
    }
    
    // 씬을 미리보기용으로 안정화하는 메서드
    private func prepareSceneForPreview() {
        guard let scene = carabinerScene else {
            return
        }
        
        // 중복된 키링 노드 제거 (혹시나 하는 안전 장치)
        cleanupDuplicateKeyrings(in: scene)
        
        // 물리 시뮬레이션 완전 비활성화
        scene.physicsWorld.speed = 0
        scene.physicsWorld.gravity = CGVector.zero
        
        // 모든 키링의 물리 속성을 고정
        for keyring in scene.keyrings {
            keyring.enumerateChildNodes(withName: "//*") { node, _ in
                node.physicsBody?.isDynamic = false
                node.physicsBody?.affectedByGravity = false
                node.removeAllActions() // 모든 애니메이션 제거
            }
        }
        
        // 카라비너도 완전히 고정
        scene.carabinerNode?.physicsBody?.isDynamic = false
        scene.carabinerNode?.physicsBody?.affectedByGravity = false
        scene.carabinerNode?.removeAllActions()
        
        // ViewModel에 안정화된 씬 저장
        viewModel.bundlePreviewScene = scene
    }
    
    // 중복된 키링 노드 정리
    private func cleanupDuplicateKeyrings(in scene: CarabinerScene) {
        guard let carabinerNode = scene.carabinerNode else { return }
        
        // 카라비너의 모든 자식 중에서 keyring_으로 시작하는 노드들 찾기
        var keyringNodes: [String: [SKNode]] = [:]
        
        carabinerNode.enumerateChildNodes(withName: "keyring_*") { node, _ in
            if let name = node.name {
                if keyringNodes[name] == nil {
                    keyringNodes[name] = []
                }
                keyringNodes[name]?.append(node)
            }
        }
        
        // 중복된 노드 제거 (첫 번째만 남기고 나머지 제거)
        for (name, nodes) in keyringNodes {
            if nodes.count > 1 {
                // 첫 번째 노드를 제외한 나머지 제거
                for i in 1..<nodes.count {
                    nodes[i].removeFromParent()
                }
            }
        }
        
        // scene.keyrings 배열도 정리
        scene.keyrings = scene.keyrings.filter { $0.parent != nil }
    }
}

//MARK: - 시트처럼 생긴 뷰, 키링 선택 스크롤뷰
extension BundleAddKeyringView {
    private var keyringSelectScrollView : some View {
        VStack {
            // 상단 타이틀
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
            
            // 스크롤뷰
            ScrollView {
                //LazyVGrid의 spacing은 vertical 간격
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.keyring, id: \.self) { keyring in
                        keyringCell(keyring: keyring)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20))
    }
    
    private func keyringCell(keyring: Keyring) -> some View {
        Button(action: {
            selectedKeyrings[selectedPosition] = keyring  // 키링 추가/교체
            withAnimation(.easeInOut) { showSelectKeyringSheet = false }
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
    
    /// 쓰레기통 버튼 클릭 되었을 때 버튼 위에 뜨는 Dual Action Capsule Button
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
                .frame(height: 20) // Divider 높이 제한
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

//MARK: - 씬 생성
extension BundleAddKeyringView {
    // 개별 키링 미니 프리뷰 씬 생성 (KeyringCellScene 사용)
    private func createMiniScene(body: String) -> KeyringCellScene {
        let scene = KeyringCellScene(
            ringType: .basic,
            chainType: .basic,
            bodyImage: body, // String으로 전달
            targetSize: CGSize(width: 100, height: 100),
            zoomScale: 1.8
        )
        scene.scaleMode = .aspectFill
        return scene
    }
    
    private func createCarabinerScene(targetSize: CGSize, screenWidth: CGFloat) -> CarabinerScene? {
        guard let carabiner = viewModel.selectedCarabiner,
              let cbImage = UIImage(named: carabiner.carabinerImage[0]) else {
            return nil
        }
        
        // 초기 씬은 키링 없이 생성 (나중에 업데이트로 추가)
        let bodyImages: [UIImage] = []
        
        let scene = CarabinerScene(
            carabiner: carabiner,
            carabinerImage: cbImage,
            ringType: .basic,
            chainType: .basic,
            bodyType: .basic,
            bodyImages: bodyImages,
            targetSize: targetSize,
            screenWidth: screenWidth,
            // 카라비너 사이즈가 화면 가로 너비의 정확히 0.5배가 되도록 zoomScale을 1.0으로 설정
            zoomScale: 1.0,
            // 뭉치 만들기 뷰에서는 물리 설정 비활성화
            isPhysicsEnabled: false
        )
        scene.scaleMode = .resizeFill
        
        // 씬 로딩 완료 콜백 설정
        scene.onSceneReady = {
            DispatchQueue.main.async {
                self.isSceneReady = true
                // 씬이 준비되면 기존 키링들이 있다면 업데이트
                if !self.selectedKeyrings.isEmpty {
                    self.needsSceneUpdate = true
                }
            }
        }
        return scene
    }
    
    // CarabinerScene 생성 또는 업데이트 (원래 방식)
    private func makeOrUpdateCarabinerScene(targetSize: CGSize, screenWidth: CGFloat) {
        // 초기 씬 생성 시에만 isSceneReady를 false로 설정
        if carabinerScene == nil {
            isSceneReady = false
        }
        
        // 카라비너 씬 새로 생성
        carabinerScene = createCarabinerScene(targetSize: targetSize, screenWidth: screenWidth)
    }
    
    // 키링만 업데이트하는 새로운 메서드
    private func updateCarabinerSceneWithKeyrings() {
        guard let scene = carabinerScene,
              let carabiner = viewModel.selectedCarabiner else {
            return
        }
        
        // selectedKeyrings에서 키링들을 수집
        var keyringData: [(index: Int, keyring: Keyring)] = []
        
        for index in 0..<carabiner.maxKeyringCount {
            if let keyring = selectedKeyrings[index] {  // 옵셔널 바인딩으로 실제 키링 존재 확인
                keyringData.append((index: index, keyring: keyring))
            }
        }
        
        // 물리 시뮬레이션이 활성화된 경우에만 조인트 제거
        if scene.isPhysicsEnabled {
            scene.physicsWorld.removeAllJoints()
        }
        
        // 기존 키링들 제거
        scene.keyrings.forEach { keyring in
            keyring.removeFromParent()
        }
        scene.keyrings.removeAll()
        
        // 키링이 없으면 바로 종료
        guard !keyringData.isEmpty else {
            return
        }
        
        // URL 또는 번들에서 이미지들을 로드
        loadKeyringImages(keyringData: keyringData) { loadedImages in
            guard let scene = self.carabinerScene else {
                return 
            }
            DispatchQueue.main.async {
                // 새 키링들을 개별적으로 위치에 맞게 생성
                if let carabinerNode = scene.carabinerNode {
                    
                    var completedKeyrings = 0
                    let totalKeyrings = keyringData.count
                    
                    // 각 키링을 올바른 위치에 개별적으로 생성
                    for (arrayIndex, (keyringIndex, _)) in keyringData.enumerated() {
                        if arrayIndex < loadedImages.count {
                            let bodyImage = loadedImages[arrayIndex]
                            
                            // 카라비너에서 실제 키링 위치 가져오기
                            let nx = scene.getKeyringXPosition(for: keyringIndex)
                            let ny = scene.getKeyringYPosition(for: keyringIndex)
                            let carabinerSize = carabinerNode.size
                            let xOffset = (nx - 0.5) * carabinerSize.width
                            let yOffset = (ny - 0.5) * carabinerSize.height
                            
                            // 개별 키링 생성
                            scene.setupKeyringNode(
                                bodyImage: bodyImage,
                                position: CGPoint(x: xOffset, y: yOffset),
                                parent: carabinerNode,
                                index: keyringIndex
                            ) { createdKeyring in
                                scene.keyrings.append(createdKeyring)
                                completedKeyrings += 1
                            }
                        }
                    }
                } else {
                    print("카라비너 노드를 찾을 수 없음")
                }
            }
        }
    }
    
    // URL 또는 번들에서 이미지들을 로드하는 메서드
    private func loadKeyringImages(
        keyringData: [(index: Int, keyring: Keyring)],
        completion: @escaping ([UIImage]) -> Void
    ) {
        let imageIdentifiers = keyringData.map { $0.keyring.bodyImage }
        
        Task {
            var loadedImages: [UIImage] = []
            
            for imageIdentifier in imageIdentifiers {
                do {
                    let image: UIImage
                    
                    if imageIdentifier.hasPrefix("http") {
                        // URL에서 이미지 로드 (StorageManager 사용)
                        image = try await StorageManager.shared.getImage(path: imageIdentifier)
                    } else {
                        // 번들에서 이미지 로드
                        guard let bundleImage = UIImage(named: imageIdentifier) else {
                            print("번들 이미지 로드 실패: \(imageIdentifier)")
                            continue
                        }
                        image = bundleImage
                    }
                    
                    loadedImages.append(image)
                } catch {
                }
            }
            
            await MainActor.run {
                completion(loadedImages)
            }
        }
    }
}

#Preview {
    BundleAddKeyringView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
