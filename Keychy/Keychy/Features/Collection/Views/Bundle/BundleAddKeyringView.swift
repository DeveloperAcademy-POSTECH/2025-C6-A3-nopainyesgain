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
struct BundleAddKeyringView<Route: BundleRoute>: View {
    // MARK: - Properties
    
    @Bindable var router: NavigationRouter<Route>
    @State var viewModel: CollectionViewModel
    
    @State private var showSelectKeyringSheet = false
    @State private var selectedKeyrings: [Int: Keyring] = [:]
    @State private var keyringOrder: [Int] = []
    @State private var selectedPosition = 0
    @State private var isCapturing = false
    @State private var sceneRefreshId = UUID()
    @State private var isSceneReady = false
    // 키링 선택 시트 그리드 컬럼
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    //임시 초기값
    private let screenSize = CGSize(width: 402, height: 874)
    private let sheetHeightRatio: CGFloat = 0.43
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 배경 + 카라비너 + 키링 씬
            ZStack(alignment: .top) {
                if let carabiner = viewModel.selectedCarabiner,
                   let background = viewModel.selectedBackground {
                    keyringEditSceneView(background: background, carabiner: carabiner)
                }
                customNavigationBar
            }
            .blur(radius: !isCapturing ? 0 : 10)
            
            
            // Dim 오버레이 (키링 시트가 열릴 때)
            if showSelectKeyringSheet || isCapturing {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(1)
                    .onTapGesture {
                        if showSelectKeyringSheet {
                            withAnimation(.easeInOut) {
                                showSelectKeyringSheet = false
                            }
                        }
                    }
                
                // 키링 선택 시트
                keyringSelectionSheet()
                    .opacity(showSelectKeyringSheet ? 1 : 0)
                
                LoadingAlert(type: .longWithKeychy, message: "뭉치 만드는 중...")
                    .opacity(isCapturing ? 1 : 0)
                    .zIndex(50)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            fetchData()
            viewModel.hideTabBar()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Toolbar
extension BundleAddKeyringView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            
        } trailing: {
            NextToolbarButton {
                Task {
                    await captureAndSaveScene()
                }
            }
            .disabled(isCapturing)
        }
    }
}

// MARK: - View Components
extension BundleAddKeyringView {
    /// 키링 편집 씬 뷰
    private func keyringEditSceneView(background: Background, carabiner: Carabiner) -> some View {
        ZStack {
            // MultiKeyringScene
            MultiKeyringSceneView(
                keyringDataList: createKeyringDataList(carabiner: carabiner),
                ringType: .basic,
                chainType: .basic,
                backgroundColor: .clear,
                backgroundImageURL: background.backgroundImage,
                carabinerBackImageURL: carabiner.backImageURL,
                carabinerFrontImageURL: carabiner.frontImageURL,
                carabinerX: carabiner.carabinerX,
                carabinerY: carabiner.carabinerY,
                carabinerWidth: carabiner.carabinerWidth,
                currentCarabinerType: carabiner.type
            )
            .ignoresSafeArea()
            .id("scene_\(background.id ?? "bg")_\(carabiner.id ?? "cb")_\(selectedKeyrings.count)_\(sceneRefreshId.uuidString)")
            
            // 키링 추가 버튼들
            keyringButtons(carabiner: carabiner)
        }
    }
    
    /// 키링 추가 버튼들
    private func keyringButtons(carabiner: Carabiner) -> some View {
        // 키링 추가 버튼들
        ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
            let xPosPt = screenWidth / screenSize.width * carabiner.keyringXPosition[index]
            let xPos = round(xPosPt * screenScale) / screenScale
            let yPosPt = screenHeight / screenSize.height * carabiner.keyringYPosition[index]
            let yPos = round(yPosPt * screenScale) / screenScale - getBottomPadding(25) - getTopPadding(34)
            CarabinerAddKeyringButton(
                isSelected: selectedPosition == index,
                action: {
                    selectedPosition = index
                    withAnimation(.easeInOut) {
                        showSelectKeyringSheet = true
                    }
                }
            )
            .position(x: xPos, y: yPos)
            .opacity(showSelectKeyringSheet && selectedPosition != index ? 0.3 : 1.0)
            .zIndex(selectedPosition == index ? 50 : 1) // 선택된 버튼이 dim 오버레이(zIndex 1) 위로 오도록
        }
    }
    
    /// 키링 선택 시트
    private func keyringSelectionSheet() -> some View {
        VStack(spacing: 18) {
            Text("키링 선택")
                .typography(.suit16B)
                .foregroundStyle(.black100)
            
            if viewModel.keyring.isEmpty {
                VStack {
                    Image(.emptyViewIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 77)
                    Text("공방에서 키링을 만들 수 있어요")
                        .typography(.suit15R)
                        .foregroundStyle(.black100)
                        .padding(.vertical, 15)
                }
                .padding(.bottom, 77)
                .padding(.top, 62)
                .frame(maxWidth: .infinity)
                
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(viewModel.keyring, id: \.self) { keyring in
                            keyringCell(keyring: keyring)
                        }
                    }
                }
            }
            
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 0, trailing: 20))
        .frame(maxWidth: .infinity)
        .frame(height: screenHeight * sheetHeightRatio)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom))
        .zIndex(2)
    }
    
    /// 키링 셀 (체크 토글 + 시트 유지)
    private func keyringCell(keyring: Keyring) -> some View {
        // 현재 선택된 위치에 이 키링이 선택되어 있는지
        let isSelectedHere: Bool = selectedKeyrings[selectedPosition]?.id == keyring.id
        // 다른 위치에 이미 선택된 키링인지 체크
        let isSelectedElsewhere: Bool = selectedKeyrings.values.contains { $0.id == keyring.id } && !isSelectedHere
        
        return Button {
            // 토글
            if isSelectedHere {
                // 해제
                selectedKeyrings[selectedPosition] = nil
                keyringOrder.removeAll { $0 == selectedPosition }
            } else if !isSelectedElsewhere {
                // 중복이 아닐 때만 선택 가능
                // 기존 있으면 순서 제거 후 교체
                if selectedKeyrings[selectedPosition] != nil {
                    keyringOrder.removeAll { $0 == selectedPosition }
                }
                selectedKeyrings[selectedPosition] = keyring
                keyringOrder.append(selectedPosition)
                // 키링 선택완료하면 시트 내림!
                withAnimation(.easeInOut) {
                    showSelectKeyringSheet = false
                }
            }
            // 중복인 경우 아무것도 하지 않음 (선택되지 않음)
            updateKeyringDataList()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 10) {
                    CollectionCellView(keyring: keyring)
                        .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                        .cornerRadius(10)
                    
                    Text("\(keyring.name)")
                        .typography(isSelectedHere ? .notosans14SB : .notosans14M)
                        .foregroundStyle(isSelectedHere ? .main500 :  .black100)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                // 중복 표시 아이콘 (다른 위치에 이미 선택됨)
                if isSelectedElsewhere {
                    VStack {
                        HStack {
                            Spacer()
                            Text("장착 중")
                                .foregroundStyle(.white100)
                                .typography(.suit13M)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.mainOpacity80)
                                )
                        }
                        Spacer()
                    }
                    .padding(.top, 5)
                    .padding(.trailing, 5)
                }
            }
        }
        .disabled(keyring.status == .packaged || keyring.status == .published || isSelectedElsewhere)
        .opacity(1.0) // 강제로 투명도 1.0 유지
    }
    
    
    /// 키링 데이터 리스트 업데이트
    private func updateKeyringDataList() {
        // 씬을 강제로 리프레시하여 키링 변경사항 즉시 반영
        sceneRefreshId = UUID()
    }
}

// MARK: - Scene Management

extension BundleAddKeyringView {
    /// 씬 캡처 및 저장
    private func captureAndSaveScene() async {
        guard let carabiner = viewModel.selectedCarabiner,
              let background = viewModel.selectedBackground else {
            return
        }
        
        // 캡처 시작
        await MainActor.run {
            isCapturing = true
            viewModel.selectedKeyringsForBundle = selectedKeyrings
        }
        
        // 배경 이미지 미리 로드
        guard let _ = try? await StorageManager.shared.getImage(path: background.backgroundImage) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }
        
        // 캡처용 키링 데이터 생성
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []
        
        for (index, keyring) in selectedKeyrings.sorted(by: { $0.key < $1.key }) {
            let data = MultiKeyringCaptureScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyring.bodyImage,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength
            )
            keyringDataList.append(data)
        }
        
        // 카라비너 이미지 추출
        let carabinerType = CarabinerType.from(carabiner.carabinerType)
        let carabinerBackURL: String?
        let carabinerFrontURL: String?
        
        if carabinerType == .hamburger {
            carabinerBackURL = carabiner.carabinerImage[1]
            carabinerFrontURL = carabiner.carabinerImage[2]
        } else {
            // plain 타입
            carabinerBackURL = carabiner.carabinerImage[0]
            carabinerFrontURL = nil
        }
        
        // 씬 캡처
        if let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: background.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,  // 카라비너 타입 전달
            carabinerX: carabiner.carabinerX,
            carabinerY: carabiner.carabinerY,
            carabinerWidth: carabiner.carabinerWidth,
        ) {
            await MainActor.run {
                viewModel.bundleCapturedImage = pngData
            }
        } else {
            print("❌ [BundleAddKeyring] 캡처 실패")
        }
        
        // 캡처 완료 후 다음 화면으로 이동
        await MainActor.run {
            isCapturing = false
            router.push(.bundleNameInputView)
        }
    }
}

// MARK: - Data Fetching

extension BundleAddKeyringView {
    /// 사용자 데이터 가져오기
    private func fetchData() {
        let uid = UserManager.shared.userUID
        
        viewModel.fetchUserCollectionData(uid: uid) { success in
            if success {
                viewModel.fetchUserKeyrings(uid: uid) { success in
                    if success {
                        // 키링 데이터 로드 완료 후 정렬 실행
                        viewModel.keyringSorting()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Methods

extension BundleAddKeyringView {
    /// 키링 데이터 리스트 생성
    private func createKeyringDataList(carabiner: Carabiner) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []
        
        // 추가된 순서대로 처리
        for index in keyringOrder {
            guard let keyring = selectedKeyrings[index] else { continue }
            let soundId = keyring.soundId
            
            // 커스텀 사운드 URL 처리
            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()
            
            let particleId = keyring.particleId
            
            // 절대 좌표 사용 (이미 절대 좌표로 저장됨)
            let position = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )
            
            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: position,
                bodyImageURL: keyring.bodyImage,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: particleId,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength
            )
            dataList.append(data)
        }
        
        return dataList
    }
}
