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
            .background(
                // 배경 이미지
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
        let uid = UserManager.shared.userUID
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
        for (_, nodes) in keyringNodes {
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
                // 키링 삭제 시 더 안전한 처리
                print("🗑️ 키링 삭제 요청 - 위치: \(selectedPosition)")
                selectedKeyrings[selectedPosition] = nil
                isDeleteButtonSelected = false
                
                // 즉시 씬 업데이트 강제 실행
                DispatchQueue.main.async {
                    self.needsSceneUpdate = true
                }
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
        let carabiner = viewModel.selectedCarabiner
        
        // 카라비너 뒷면/앞면 이미지 URL 로드 후 씬 생성
        if let backImageURL = carabiner?.carabinerImage[1],
           let frontImageURL = carabiner?.carabinerImage[2] {
            Task {
                do {
                    // 뒷면과 앞면 이미지를 동시에 로드
                    async let backImage = StorageManager.shared.getImage(path: backImageURL)
                    async let frontImage = StorageManager.shared.getImage(path: frontImageURL)
                    
                    let loadedBackImage = try await backImage
                    let loadedFrontImage = try await frontImage
                    
                    await MainActor.run {
                        // 뒷면/앞면 이미지가 준비된 후 씬 생성 (물리 시뮬레이션 활성화)
                        let scene = CarabinerScene(
                            carabiner: carabiner,
                            carabinerImage: loadedBackImage, // 뒷면 이미지를 기본으로 사용
                            ringType: .basic,
                            chainType: .basic,
                            bodyType: .basic,
                            bodyImages: [],
                            targetSize: targetSize,
                            screenWidth: screenWidth,
                            zoomScale: 1.0,
                            isPhysicsEnabled: true  // 물리 시뮬레이션 활성화
                        )
                        // 앞면 이미지를 씬에 전달 (나중에 오버레이용으로 사용)
                        scene.carabinerFrontImage = loadedFrontImage
                        
                        scene.scaleMode = SKSceneScaleMode.resizeFill
                        scene.onSceneReady = {
                            DispatchQueue.main.async {
                                self.isSceneReady = true
                                if !self.selectedKeyrings.isEmpty {
                                    self.needsSceneUpdate = true
                                }
                            }
                        }
                        self.carabinerScene = scene
                    }
                } catch {
                    print("카라비너 이미지 로드 실패: \(error)")
                }
            }
        }
        
        return nil // 비동기로 나중에 설정될 예정
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
    
    // 키링만 업데이트하는 새로운 메서드 (개선된 버전)
    private func updateCarabinerSceneWithKeyrings() {
        guard let scene = carabinerScene,
              let carabiner = viewModel.selectedCarabiner else {
            return
        }
        
        print("🔄 씬 업데이트 시작 - 현재 selectedKeyrings: \(selectedKeyrings)")
        
        // selectedKeyrings에서 키링들을 수집
        var keyringData: [(index: Int, keyring: Keyring)] = []
        
        for index in 0..<carabiner.maxKeyringCount {
            if let keyring = selectedKeyrings[index] {  // 옵셔널 바인딩으로 실제 키링 존재 확인
                keyringData.append((index: index, keyring: keyring))
            }
        }
        
        print("🔄 새로 생성할 키링 데이터: \(keyringData.count)개")
        
        // 기존 키링들과 관련된 모든 노드 완전 제거
        removeAllKeyringComponents(from: scene)
        
        // 키링이 없으면 종료
        guard !keyringData.isEmpty else {
            print("🔄 키링이 없음 - 업데이트 완료")
            return
        }
        
        // 이미지들을 로드
        loadKeyringImages(keyringData: keyringData) { loadedImages in
            guard let scene = self.carabinerScene else {
                return
            }
            DispatchQueue.main.async {
                print("🔄 \(loadedImages.count)개 키링 이미지 로드 완료")
                
                // 각 키링을 올바른 위치에 개별적으로 생성
                if let carabinerNode = scene.carabinerNode {
                    for (arrayIndex, (keyringIndex, _)) in keyringData.enumerated() {
                        if arrayIndex < loadedImages.count {
                            let bodyImage = loadedImages[arrayIndex]
                            
                            // 카라비너에서 실제 키링 위치 가져오기 (선택된 위치)
                            let nx = scene.getKeyringXPosition(for: keyringIndex)
                            let ny = scene.getKeyringYPosition(for: keyringIndex)
                            let carabinerSize = carabinerNode.size
                            
                            // scaleFactor를 적용한 오프셋 계산
                            let xOffset = (nx - 0.5) * carabinerSize.width * scene.scaleFactor
                            let yOffset = (ny - 0.5) * carabinerSize.height * scene.scaleFactor
                            
                            // 카라비너의 절대 위치에서 상대적 위치 계산
                            let absoluteX = carabinerNode.position.x + xOffset
                            let absoluteY = carabinerNode.position.y + yOffset
                            
                            print("🎯 Keyring \(keyringIndex) 생성 중 - position: (\(absoluteX), \(absoluteY))")
                            
                            // 개별 키링 생성
                            self.createIndividualKeyring(
                                scene: scene,
                                bodyImage: bodyImage,
                                position: CGPoint(x: absoluteX, y: absoluteY),
                                index: keyringIndex
                            )
                        }
                    }
                    
                    // 씬 상태 확인 디버깅
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.debugSceneState(scene: scene)
                    }
                }
            }
        }
    }
    
    // 모든 키링 구성 요소를 완전히 제거하는 메서드
    private func removeAllKeyringComponents(from scene: CarabinerScene) {
        print("🗑️ 기존 키링 구성 요소 완전 제거 시작")
        
        // 1. 모든 물리 조인트 제거 (카라비너는 제외)
        scene.physicsWorld.removeAllJoints()
        
        // 2. 키링 관련 모든 노드 찾아서 제거
        var nodesToRemove: [SKNode] = []
        
        scene.enumerateChildNodes(withName: "//*keyring*") { node, _ in
            nodesToRemove.append(node)
        }
        
        // 3. 찾은 노드들 제거
        for node in nodesToRemove {
            print("🗑️ 제거: \(node.name ?? "unnamed node")")
            node.removeAllActions() // 모든 액션 제거
            node.removeFromParent() // 부모에서 제거
        }
        
        // 4. scene.keyrings 배열 초기화
        scene.keyrings.removeAll()
        
        print("🗑️ 키링 구성 요소 제거 완료 - 제거된 노드: \(nodesToRemove.count)개")
    }
    
    // 씬 상태 디버깅 메서드
    private func debugSceneState(scene: CarabinerScene) {
        print("🔍 씬 상태 디버깅:")
        print("   - 전체 자식 노드 수: \(scene.children.count)")
        print("   - 키링 배열 크기: \(scene.keyrings.count)")
        print("   - 물리 조인트 수: 정보 없음") // SKPhysicsWorld에서 조인트 수를 직접 가져올 수 없음
        
        // 키링 관련 노드 카운트
        var keyringNodeCount = 0
        scene.enumerateChildNodes(withName: "//*keyring*") { node, _ in
            keyringNodeCount += 1
            if let nodeName = node.name {
                print("   - 발견된 키링 노드: \(nodeName)")
            }
        }
        print("   - keyring 이름을 가진 노드 수: \(keyringNodeCount)")
        
        // selectedKeyrings 상태 확인
        print("   - selectedKeyrings: \(selectedKeyrings)")
    }
    
    // URL에서 이미지들을 로드하는 메서드
    private func loadKeyringImages(
        keyringData: [(index: Int, keyring: Keyring)],
        completion: @escaping ([UIImage]) -> Void
    ) {
        let imageIdentifiers = keyringData.map { $0.keyring.bodyImage }
        
        Task {
            var loadedImages: [UIImage] = []
            
            for imageIdentifier in imageIdentifiers {
                do {
                    // URL에서 이미지 로드 (StorageManager 사용)
                    let image = try await StorageManager.shared.getImage(path: imageIdentifier)
                    loadedImages.append(image)
                } catch {
                    print("키링 이미지 로드 실패: \(imageIdentifier), 에러: \(error)")
                }
            }
            
            await MainActor.run {
                completion(loadedImages)
            }
        }
    }
    
    // 개별 키링을 직접 생성하는 메서드 (디버깅 포함)
    private func createIndividualKeyring(
        scene: CarabinerScene,
        bodyImage: UIImage,
        position: CGPoint,
        index: Int
    ) {
        print("🔴 Starting keyring creation at position: \(position)")
        
        // 1. Ring 생성
        KeyringRingComponent.createNode(from: scene.currentRingType) { ring in
            guard let ring = ring else { 
                print("❌ Ring creation failed for index \(index)")
                return 
            }
            
            // Ring 위치 설정 (scaleFactor 적용)
            ring.setScale(0.6 * scene.scaleFactor)
            ring.name = "keyring_\(index)_ring"
            
            let ringFrame = ring.calculateAccumulatedFrame()
            let ringRadius = ringFrame.height / 2
            let ringCenterY = position.y - ringRadius
            
            ring.position = CGPoint(x: position.x, y: ringCenterY)
            ring.physicsBody?.isDynamic = false
            ring.physicsBody?.affectedByGravity = false
            ring.zPosition = 1
            
            // 키링별로 고유한 충돌 그룹 설정
            if let physicsBody = ring.physicsBody {
                physicsBody.categoryBitMask = UInt32(1 << (index % 31))  // 키링별 고유 카테고리
                physicsBody.collisionBitMask = 0  // 다른 키링과 충돌하지 않음
                physicsBody.contactTestBitMask = 0  // 접촉 감지 안함
            }
            
            scene.addChild(ring)
            
            print("🔴 Ring added: x=\(ring.position.x), y=\(ring.position.y), scale=\(ring.xScale)")
            
            // 2. Chain 생성
            self.createChainForKeyring(scene: scene, ring: ring, bodyImage: bodyImage, index: index)
        }
    }
    
    // 키링의 체인 생성 (KeyringScene과 동일한 물리 설정 + 위치 디버깅)
    private func createChainForKeyring(
        scene: CarabinerScene,
        ring: SKSpriteNode,
        bodyImage: UIImage,
        index: Int
    ) {
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        let chainStartY = ringBottomY + 0.5
        let chainSpacing: CGFloat = 16 * scene.scaleFactor
        
        print("🔵 Chain creation: ringBottom=\(ringBottomY), chainStart=\(chainStartY), spacing=\(chainSpacing)")
        
        KeyringChainComponent.createLinks(
            from: scene.currentChainType,
            count: 5,
            startPosition: CGPoint(x: ring.position.x, y: chainStartY),
            spacing: chainSpacing
        ) { chains in
            print("🔵 Created \(chains.count) chain links")
            
            // 체인들을 씬에 추가 (키링별 충돌 방지 설정)
            for (i, chain) in chains.enumerated() {
                chain.setScale(scene.scaleFactor)
                chain.name = "keyring_\(index)_chain_\(i)"
                chain.zPosition = 1
                
                // 키링별로 고유한 충돌 그룹 설정하여 다른 키링과 충돌 방지
                if let physicsBody = chain.physicsBody {
                    physicsBody.categoryBitMask = UInt32(1 << (index % 31))  // 키링별 고유 카테고리 (31개까지)
                    physicsBody.collisionBitMask = 0  // 다른 키링과 충돌하지 않음
                    physicsBody.contactTestBitMask = 0  // 접촉 감지 안함
                }
                
                scene.addChild(chain)
                print("🔵 Chain \(i) added for keyring \(index) with collision group \(1 << (index % 31))")
            }
            
            // 3. Body 생성
            self.createBodyForKeyring(scene: scene, ring: ring, chains: chains, bodyImage: bodyImage, index: index)
        }
    }
    
    // 키링의 몸체 생성 (KeyringScene과 동일한 물리 설정 + 위치 디버깅)
    private func createBodyForKeyring(
        scene: CarabinerScene,
        ring: SKSpriteNode,
        chains: [SKSpriteNode],
        bodyImage: UIImage,
        index: Int
    ) {
        print("🟢 Starting body creation for index \(index)")
        
        KeyringBodyComponent.createNode(from: bodyImage) { body in
            guard let body = body else { 
                print("❌ Body creation failed for index \(index)")
                return 
            }
            
            body.setScale(0.3 * scene.scaleFactor)
            body.name = "keyring_\(index)_body"
            
            // 키링별로 고유한 충돌 그룹 설정하여 다른 키링과 충돌 방지
            if let physicsBody = body.physicsBody {
                physicsBody.categoryBitMask = UInt32(1 << (index % 31))  // 키링별 고유 카테고리
                physicsBody.collisionBitMask = 0  // 다른 키링과 충돌하지 않음
                physicsBody.contactTestBitMask = 0  // 접촉 감지 안함
            }
            
            // Body 위치 계산 (KeyringScene과 동일한 방식)
            let ringHeight = ring.calculateAccumulatedFrame().height
            let ringBottomY = ring.position.y - ringHeight / 2
            let chainStartY = ringBottomY + 0.5
            let chainSpacing: CGFloat = 16 * scene.scaleFactor
            
            let bodyFrame = body.calculateAccumulatedFrame()
            let bodyHalfHeight = bodyFrame.height / 2
            
            let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
            let lastLinkHeight: CGFloat = chains.last?.calculateAccumulatedFrame().height ?? chainSpacing
            let lastChainBottomY = lastChainY - lastLinkHeight / 2
              
            let connectGap = 30.0 * scene.scaleFactor
            let bodyCenterY = lastChainBottomY - bodyHalfHeight + connectGap
            
            // 화면 경계 체크 및 조정
            let minY = bodyHalfHeight
            let maxY = scene.size.height - bodyHalfHeight
            let clampedY = max(minY, min(maxY, bodyCenterY))
            
            if clampedY != bodyCenterY {
                print("⚠️ Body Y position clamped from \(bodyCenterY) to \(clampedY)")
            }
            
            body.position = CGPoint(x: ring.position.x, y: clampedY)
            body.zPosition = 1
            
            print("🟢 Body position calculation:")
            print("   ringBottomY: \(ringBottomY)")
            print("   chainStartY: \(chainStartY)")
            print("   lastChainY: \(lastChainY)")
            print("   lastChainBottomY: \(lastChainBottomY)")
            print("   bodyHalfHeight: \(bodyHalfHeight)")
            print("   connectGap: \(connectGap)")
            print("   bodyCenterY: \(bodyCenterY)")
            print("   final position: \(body.position)")
            
            // KeyringScene과 동일: Component에서 설정된 기본 물리 속성 유지
            // isDynamic, affectedByGravity 등을 따로 설정하지 않음
            
            scene.addChild(body)
            scene.keyrings.append(body) // 키링 배열에 추가
            
            print("🟢 Body added: x=\(body.position.x), y=\(body.position.y), scale=\(body.xScale)")
            
            // KeyringScene과 동일한 방식으로 물리 조인트 연결
            self.connectKeyringComponents(scene: scene, ring: ring, chains: chains, body: body)
        }
    }
    
    // KeyringScene과 동일한 물리 조인트 연결 메서드 (안정성 개선)
    private func connectKeyringComponents(
        scene: CarabinerScene,
        ring: SKSpriteNode,
        chains: [SKSpriteNode],
        body: SKNode
    ) {
        // 물리 시뮬레이션이 비활성화된 경우 조인트 연결 안함
        guard scene.isPhysicsEnabled else {
            print("🔗 물리 시뮬레이션 비활성화 - 조인트 연결 생략")
            return
        }
        
        print("🔗 KeyringScene 방식 조인트 연결 시작 - 키링 \(ring.name ?? "unknown")")
        
        // 조인트 연결 전 물리체 검증
        guard let ringPhysics = ring.physicsBody else {
            print("❌ Ring 물리체 없음 - 조인트 연결 실패")
            return
        }
        
        var previousNode: SKNode = ring

        // Ring과 첫 번째 Chain 연결
        if let firstChain = chains.first,
           let firstChainPhysics = firstChain.physicsBody {
            
            // Ring은 항상 고정
            ringPhysics.isDynamic = false
            ringPhysics.affectedByGravity = false
            
            // 체인은 물리 활성화
            firstChainPhysics.isDynamic = true
            firstChainPhysics.affectedByGravity = true
            
            // Pin 조인트로 연결
            let joint = SKPhysicsJointPin.joint(
                withBodyA: ringPhysics,
                bodyB: firstChainPhysics,
                anchor: CGPoint(
                    x: (ring.position.x + firstChain.position.x) / 2,
                    y: ring.position.y
                )
            )
            joint.shouldEnableLimits = false
            joint.frictionTorque = 0.1
            scene.physicsWorld.add(joint)
            
            // 거리 제한으로 안정성 확보
            let distance = hypot(
                firstChain.position.x - ring.position.x,
                firstChain.position.y - ring.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: ringPhysics,
                bodyB: firstChainPhysics,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = max(distance * 1.05, 20.0) // 최소 거리 보장
            scene.physicsWorld.add(limitJoint)
            
            // 체인의 물리 속성 조정 - 더 안정적으로
            firstChainPhysics.linearDamping = 0.8  // 높은 댐핑으로 안정성 증대
            firstChainPhysics.angularDamping = 0.8
            
            previousNode = firstChain
        }

        // Chain 링크들 연결 - 더 안전하게 물리체 검증
        for i in 1..<chains.count {
            let current = chains[i]
            guard let currentPhysics = current.physicsBody,
                  let previousPhysics = previousNode.physicsBody else {
                print("❌ 체인 \(i) 물리체 검증 실패")
                continue
            }
            
            // 체인 물리 활성화
            currentPhysics.isDynamic = true
            currentPhysics.affectedByGravity = true
            
            let joint = SKPhysicsJointPin.joint(
                withBodyA: previousPhysics,
                bodyB: currentPhysics,
                anchor: CGPoint(
                    x: (previousNode.position.x + current.position.x) / 2,
                    y: (previousNode.position.y + current.position.y) / 2
                )
            )
            joint.shouldEnableLimits = false
            joint.frictionTorque = 0.1
            scene.physicsWorld.add(joint)
            
            // 거리 제한 - 최소값 보장으로 안정성 확보
            let distance = hypot(
                current.position.x - previousNode.position.x,
                current.position.y - previousNode.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: previousPhysics,
                bodyB: currentPhysics,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = max(distance * 1.05, 15.0) // 최소 거리 보장
            scene.physicsWorld.add(limitJoint)
            
            // 체인의 물리 속성 조정
            currentPhysics.linearDamping = 0.8
            currentPhysics.angularDamping = 0.8
            
            previousNode = current
        }

        // 마지막 Chain과 Body 연결 - 안전한 물리체 검증
        if let lastChain = chains.last,
           let lastChainPhysics = lastChain.physicsBody,
           let bodyPhysics = body.physicsBody {
            
            // Body 물리 활성화
            bodyPhysics.isDynamic = true
            bodyPhysics.affectedByGravity = true
            
            let joint = SKPhysicsJointFixed.joint(
                withBodyA: lastChainPhysics,
                bodyB: bodyPhysics,
                anchor: CGPoint(
                    x: lastChain.position.x,
                    y: lastChain.position.y
                )
            )
            scene.physicsWorld.add(joint)
            
            // Body와 Chain 사이 거리 제한
            let distance = hypot(
                body.position.x - lastChain.position.x,
                body.position.y - lastChain.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: lastChainPhysics,
                bodyB: bodyPhysics,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = max(distance * 1.05, 25.0) // 최소 거리 보장
            scene.physicsWorld.add(limitJoint)
            
            // Body의 물리 속성 조정 - 더 안정적으로
            bodyPhysics.linearDamping = 0.9  // 몸체는 더 안정적으로
            bodyPhysics.angularDamping = 0.9
        }
        
        print("🔗 KeyringScene 방식 조인트 연결 완료 - 키링 \(ring.name ?? "unknown")")
    }
}

#Preview {
    BundleAddKeyringView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
