//
//  BundleDetailView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//
// 키링 뭉치 상세보기 화면 - 선택한 뭉치의 키링들을 3D 씬으로 표시

import SwiftUI
import NukeUI
import FirebaseFirestore

struct BundleDetailUIState {
    var showMenu = false
    var showDeleteAlert = false
    var showDeleteCompleteToast = false
    var showAlreadyMainBundleToast = false
    var showChangeMainBundleAlert = false
    var isMainBundleChange = false
    var isCapturing = false
    
    mutating func resetOverlays() {
        showMenu = false
        showDeleteAlert = false
        showDeleteCompleteToast = false
        showAlreadyMainBundleToast = false
        showChangeMainBundleAlert = false
        isMainBundleChange = false
    }
}

struct BundleDetailView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var collectionVM: CollectionViewModel
    @State var bundleVM: BundleViewModel
    
    // MARK: - State Management
    @State var uiState = BundleDetailUIState()
    @State var getlessPadding: CGFloat = 0
    @State var menuPosition: CGRect = .zero
    @State var isNavigatingDeeper: Bool = true
    @State private var dismissTask: Task<Void, Never>?
    @State private var readyDelayTask: Task<Void, Never>?
    
    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []
    
    /// 씬 준비 완료 여부
    @State var isSceneReady = false
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ZStack(alignment: .top) {
                    if let bundle = bundleVM.selectedBundle,
                       let carabiner = bundleVM.resolveCarabiner(from: bundle.selectedCarabiner),
                       let background = bundleVM.selectedBackground {
                        
                        MultiKeyringSceneView(
                            keyringDataList: keyringDataList,
                            ringType: .basic,
                            chainType: .basic,
                            backgroundColor: .clear,
                            backgroundImageURL: background.backgroundImage,
                            carabinerBackImageURL: carabiner.backImageURL,
                            carabinerFrontImageURL: carabiner.frontImageURL,
                            carabinerX: carabiner.carabinerX,
                            carabinerY: carabiner.carabinerY,
                            carabinerWidth: carabiner.carabinerWidth,
                            currentCarabinerType: carabiner.type,
                            onAllKeyringsReady: {
                                // 기존 딜레이 작업 취소
                                readyDelayTask?.cancel()
                                
                                // 0.5초 딜레이 후 준비 완료로 설정 (물리 엔진 안정화 대기)
                                readyDelayTask = Task {
                                    try? await Task.sleep(for: .seconds(0.5)) // 0.5초 대기
                                    if !Task.isCancelled {
                                        await MainActor.run {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                isSceneReady = true
                                            }
                                            // 마지막으로 로드한 구성 id를 뷰모델에 저장 (뷰모델이 다음 진입 시 동일 구성 판정)
                                            bundleVM.updateLastConfigIds(
                                                background: bundleVM.selectedBackground,
                                                carabiner: bundleVM.selectedCarabiner,
                                                keyringDataList: keyringDataList
                                            )
                                        }
                                    }
                                }
                            } //: onAllKeyringsReady
                        )
                        .animation(.easeInOut(duration: 0.3), value: isSceneReady)
                        /// 씬 재생성 조건을 위한 ID 설정 -> 배경, 카라비너, 키링 구성이 변경되면 씬을 완전히 재생성
                        .id("scene_\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map { "\($0.index)_\($0.bodyImageURL.hashValue)" }.joined(separator: "_"))")
                        .onAppear {
                            bundleVM.returnBackgroundId = bundle.selectedBackground
                            bundleVM.returnCarabinerId = bundle.selectedCarabiner
                            bundleVM.returnKeyringsId = bundle.keyrings
                                .sorted()
                                .joined(separator: "|")
                        }
                        
                        VStack {
                            Spacer()
                            bottomSection
                        }
                    }
                    menuOverlay
                    
                    customnavigationBar
                }
                .blur(radius: (isSceneReady && !uiState.isMainBundleChange && !uiState.isCapturing) ? 0 : 15)
                .ignoresSafeArea()
                
                alertOverlays
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .withToast(position: .default)
        .onPreferenceChange(MenuButtonPreferenceKey.self) { frame in
            if frame != .zero {
                menuPosition = frame
            }
        }
        .onAppear {
            isNavigatingDeeper = false
            uiState.resetOverlays()
            collectionVM.hideTabBar()
            getlessPadding = (getBottomPadding(0) == 0) ? 25 : 0
        }
        .onDisappear {
            uiState.resetOverlays()
            
            // 진행 중인 작업들 취소
            readyDelayTask?.cancel()
            dismissTask?.cancel()
        }
        .task {
            await handleBundleChange()
        }
        
        .onChange(of: uiState.showAlreadyMainBundleToast) { oldValue, newValue in
            if newValue {
                dismissTask?.cancel()
                
                dismissTask = Task {
                    try? await Task.sleep(for: .seconds(1))
                    if !Task.isCancelled {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            uiState.showAlreadyMainBundleToast = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Data Loading
extension BundleDetailView {
    private var bundleTaskId: String {
        "\(bundleVM.selectedBundle?.keyrings ?? [])_\(bundleVM.selectedBundle?.selectedBackground ?? "")_\(bundleVM.selectedBundle?.selectedCarabiner ?? "")"
    }
    
    /// 선택된 뭉치 데이터를 로드하고 뷰 상태를 초기화
    /// 1. 배경 및 카라비너 데이터 로드
    /// 2. 선택된 뭉치의 배경과 카라비너 설정
    /// 3. 선택된 뭉치의 키링들을 Firestore에서 가져와 KeyringData 리스트 생성
    @MainActor
    private func loadBundleData() async {
        
        // 1. 배경 및 카라비너 데이터 로드
        await collectionVM.loadBackgroundsAndCarabiners()
        
        // 2. 선택된 뭉치의 배경과 카라비너 설정
        guard let bundle = bundleVM.selectedBundle else {
            // 데이터가 없으면 오버레이가 영원히 남지 않도록 최소 복구
            isSceneReady = true
            return
        }
        bundleVM.selectedBackground = bundleVM.resolveBackground(from: bundle.selectedBackground)
        bundleVM.selectedCarabiner = bundleVM.resolveCarabiner(from: bundle.selectedCarabiner)
        
        // 3. 키링 데이터 생성
        guard let carabiner = bundleVM.selectedCarabiner else {
            // 카라비너 resolve 실패 시에도 최소 복구
            isSceneReady = true
            return
        }

        let newKeyringDataList = await bundleVM.createKeyringDataList(bundle: bundle, carabiner: carabiner)
        keyringDataList = newKeyringDataList
        
        // 키링 데이터까지 불러오고 난 후에도 키링의 개수가 0개라면 바로 씬을 준비 완료 상태로 체크
        if newKeyringDataList.isEmpty {
            isSceneReady = true
        }
    }
    
    /// 뭉치 삭제
    @MainActor
    func deleteBundle() async {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            uiState.showDeleteAlert = false
            ToastManager.shared.show()
            return
        }
        
        guard let bundle = bundleVM.selectedBundle,
              let documentId = bundle.documentId else {
            uiState.showDeleteAlert = false
            return
        }
        
        do {
            // 1. 삭제 확인 Alert 닫기
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                uiState.showDeleteAlert = false
            }
            
            // 2. alert가 확실히 사라지면서 중첩되지 않도록 보장하는 아주 짧은 대기 시간을 줌
            await Task.yield()
            try? await Task.sleep(for: .seconds(0.25))
            
            let db = Firestore.firestore()
            
            // 3. Firebase에서 문서 삭제
            try await db.collection("KeyringBundle").document(documentId).delete()
            
            // 4. 로컬 배열에서도 제거
            bundleVM.bundles.removeAll { $0.documentId == documentId }
            
            // 5. 삭제 완료 팝업 표시
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                uiState.showDeleteCompleteToast = true
            }
            
            // 6. 1초 후 팝업 닫고 이전 화면으로 이동
            try? await Task.sleep(for: .seconds(1))
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                uiState.showDeleteCompleteToast = false
            }
            
            // 7. 애니메이션 완료 대기 후 화면 이동
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4초
            
            router.pop()
            
        } catch {
            print("[BundleDetail] 뭉치 삭제 실패: \(error.localizedDescription)")
            uiState.showDeleteAlert = false
        }
    }
    
    // 뭉치 상태 변경 확인 및 처리 함수
    @MainActor
    private func handleBundleChange() async {
        guard let bundle = bundleVM.selectedBundle else { return }
        // 동일 구성인지 확인(+변경 감지)
        if bundleVM.shouldSkipReloadForReturnedConfig() {
            restoreSceneIfNeeded(bundle)
            isSceneReady = true
            return
        }
        isSceneReady = false
        readyDelayTask?.cancel()
        readyDelayTask = nil
        
        await loadBundleData()
    }
    
    @MainActor
    private func restoreSceneIfNeeded(_ bundle: KeyringBundle) {
        // 동일 구성일 때 리로드 스킵 및 필요 시 즉시 준비 완료 복구
        // Scene이 바로 그려질 수 있도록 최소 resolve 보장
        if bundleVM.selectedBackground == nil {
            bundleVM.selectedBackground = bundleVM.resolveBackground(from: bundle.selectedBackground)
        }
        if bundleVM.selectedCarabiner == nil {
            bundleVM.selectedCarabiner = bundleVM.resolveCarabiner(from: bundle.selectedCarabiner)
        }
        readyDelayTask?.cancel()
        readyDelayTask = nil
        isSceneReady = true
    }
}


// MARK: - 구성 id 생성 헬퍼
extension BundleDetailView {
    private func makeKeyringsIdForCheckBundleChanged(_ list: [MultiKeyringScene.KeyringData]) -> String {
        list
            .sorted(by: { $0.index < $1.index })
            .map { item in
                "\(item.index)|\(item.bodyImageURL)|\((item.templateId ?? ""))|\(item.soundId)|\(item.particleId)"
            }
            .joined(separator: ";")
    }
}


// MARK: - 커스텀 네비게이션 바
extension BundleDetailView {
    private var customnavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                bundleVM.lastKeyringsIdForDetail = ""
                bundleVM.lastCarabinerIdForDetail = ""
                bundleVM.lastBackgroundIdForDetail = ""
                router.pop()
            }
        } center: {
            if let bundle = bundleVM.selectedBundle {
                Text("\(bundle.name)")
            }
        } trailing: {
            MenuToolbarButton {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    uiState.showMenu.toggle()
                }
            }
        }
    }
}

// MARK: - View Components
extension BundleDetailView {
    /// 하단 정보 섹션 - 핀 버튼, 뭉치 이름/개수, 다운로드 버튼
    private var bottomSection: some View {
        VStack {
            Spacer()
            HStack {
                pinButton
                
                Spacer()
                
                if let bundle = bundleVM.selectedBundle {
                    if bundle.isMain {
                        Text("대표 뭉치 설정 중")
                            .typography(.suit16M)
                            .foregroundStyle(.white100)
                            .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.main500)
                            )
                    }
                }
                
                Spacer()
                
                downloadImageButton
            }
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 36, trailing: 16))
    }
    
    /// 핀 버튼 - 메인 뭉치 설정/해제
    private var pinButton: some View {
        Group {
            if let bundle = bundleVM.selectedBundle {
                if bundle.isMain {
                    Button {
                        uiState.showAlreadyMainBundleToast = true
                    } label: {
                        Image(.starFill)
                    }
                    .frame(width: 48, height: 48)
                    .glassEffect(in: .circle)
                } else {
                    // 메인으로 설정되지 않은 경우 버튼으로 표시
                    Button(action: {
                        // 네트워크 체크
                        guard NetworkManager.shared.isConnected else {
                            ToastManager.shared.show()
                            return
                        }
                        
                        uiState.showChangeMainBundleAlert = true
                    }) {
                        Image(.star)
                    }
                    .frame(width: 48, height: 48)
                    .glassEffect(in: .circle)
                }
            }
        }
    }
    
    /// 이미지 다운로드 버튼
    private var downloadImageButton: some View {
        Button(action: {
            Task {
                await captureAndSaveScene()
            }
        }) {
            Image(.imageDownload)
        }
        .disabled(uiState.isCapturing)
        .frame(width: 48, height: 48)
        .glassEffect(in: .circle)
    }
}
