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

struct BundleDetailView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var viewModel: CollectionViewModel
    
    // MARK: - State Management
    @State private var showMenu: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteCompleteToast: Bool = false
    @State private var showAlreadyMainBundleToast: Bool = false
    @State private var showChangeMainBundleAlert: Bool = false
    @State private var isMainBundleChange: Bool = false
    @State var isCapturing: Bool = false
    @State var getlessPadding: CGFloat = 0
    @State private var isNavigatingDeeper: Bool = true
    @State private var menuPosition: CGRect = .zero
    @State private var dismissTask: Task<Void, Never>?
    @State private var readyDelayTask: Task<Void, Never>?
    
    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []
    
    /// 씬 준비 완료 여부
    @State private var isSceneReady = false
    
    /// 마지막으로 로드된 번들의 상태 (변경 감지용)
    @State private var lastLoadedKeyrings: [String] = []
    @State private var lastLoadedBackground: String = ""
    @State private var lastLoadedCarabiner: String = ""
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ZStack(alignment: .top) {
                    if let bundle = viewModel.selectedBundle,
                       let carabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner),
                       let background = viewModel.selectedBackground {
                        
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
                                print("[BundleDetail] 씬 준비 완료 콜백 호출됨")
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
                                        }
                                    }
                                }
                            }
                        )
                        .animation(.easeInOut(duration: 0.3), value: isSceneReady)
                        /// 씬 재생성 조건을 위한 ID 설정
                        /// 배경, 카라비너, 키링 구성이 변경되면 씬을 완전히 재생성
                        .id("scene_\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map { "\($0.index)_\($0.bodyImageURL.hashValue)" }.joined(separator: "_"))")
                        
                        // 하단 섹션을 ZStack 안에서 직접 배치
                        VStack {
                            Spacer()
                            bottomSection
                        }
                    }
                    customnavigationBar
                }
                .blur(radius: (isSceneReady && !isMainBundleChange && !isCapturing) ? 0 : 15)
                .ignoresSafeArea()
                
                // 메뉴 오버레이 (최상위 ZStack으로 이동)
                if showMenu {
                    menuOverlay
                }
                
                if !isSceneReady || showChangeMainBundleAlert || isMainBundleChange || isCapturing || showDeleteAlert || showDeleteCompleteToast || showAlreadyMainBundleToast {
                    Color.black20
                        .ignoresSafeArea()
                    
                    LoadingAlert(type: .longWithKeychy, message: "뭉치를 불러오고 있어요")
                        .zIndex(200)
                        .opacity(isSceneReady ? 0 : 1)
                    
                    changeMainBundleAlert
                        .opacity(showChangeMainBundleAlert ? 1 : 0)
                        .padding(.horizontal, 51)
                        .position(x: screenWidth/2, y: screenHeight/2)
                    
                    KeychyAlert(type: .checkmark, message: "대표 뭉치가 변경되었어요!", isPresented: $isMainBundleChange)
                        .zIndex(200)
                    
                    KeychyAlert(type: .imageSave, message: "이미지가 저장되었어요!", isPresented: $isCapturing)
                        .zIndex(200)

                    if showDeleteAlert {
                        if let bundle = viewModel.selectedBundle {
                            DeletePopup(
                                title: "[\(bundle.name)]\n삭제하시겠어요?",
                                message: "삭제한 뭉치는 복구할 수 없습니다.",
                                onCancel: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showDeleteAlert = false
                                    }
                                },
                                onConfirm: {
                                    Task {
                                        await deleteBundle()
                                    }
                                }
                            )
                            .position(x: screenWidth/2, y: screenHeight/2)
                            .zIndex(200)
                        }
                    } else if showDeleteCompleteToast {
                        DeleteCompletePopup(isPresented: $showDeleteCompleteToast)
                            .zIndex(200)
                            .position(x: screenWidth/2, y: screenHeight/2)
                    }
                    
                    alreadyMainBundleToast
                        .zIndex(200)
                        .opacity(showAlreadyMainBundleToast ? 1 : 0)
                        .padding(.horizontal, 51)
                        .position(x: screenWidth/2, y: screenHeight/2)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onPreferenceChange(MenuButtonPreferenceKey.self) { frame in
            if frame != .zero {
                menuPosition = frame
            }
        }
        .onAppear {
            isNavigatingDeeper = false
            showDeleteCompleteToast = false
            showAlreadyMainBundleToast = false
            showChangeMainBundleAlert = false
            isMainBundleChange = false
            showDeleteAlert = false
            showMenu = false
            viewModel.hideTabBar()
            getlessPadding = (getBottomPadding(0) == 0) ? 25 : 0
            
            // 씬 준비 상태 초기화 및 진행 중인 딜레이 작업 취소
            isSceneReady = false
            readyDelayTask?.cancel()
            
            // 데이터 재로드를 위한 상태 초기화
            if viewModel.selectedBundle != nil {
                lastLoadedKeyrings = []
                lastLoadedBackground = ""
                lastLoadedCarabiner = ""
            }
        }
        .onDisappear {
            // Alert/Toast 상태 초기화
            showDeleteCompleteToast = false
            showAlreadyMainBundleToast = false
            showChangeMainBundleAlert = false
            isMainBundleChange = false
            showDeleteAlert = false
            showMenu = false
            
            // 진행 중인 작업들 취소
            readyDelayTask?.cancel()
            dismissTask?.cancel()
        }
        .task(id: "\(viewModel.selectedBundle?.keyrings ?? [])_\(viewModel.selectedBundle?.selectedBackground ?? "")_\(viewModel.selectedBundle?.selectedCarabiner ?? "")") {
            guard let bundle = viewModel.selectedBundle else {
                return
            }
            
            // 키링, 배경, 카라비너가 변경되었는지 확인
            let hasKeyringChanged = bundle.keyrings != lastLoadedKeyrings
            let hasBackgroundChanged = bundle.selectedBackground != lastLoadedBackground
            let hasCarabinerChanged = bundle.selectedCarabiner != lastLoadedCarabiner
            let hasChanged = hasKeyringChanged || hasBackgroundChanged || hasCarabinerChanged
            
            // 최초 로드이거나 데이터가 변경된 경우에만 로드
            if (keyringDataList.isEmpty || hasChanged) {
                // 씬 준비 상태를 false로 설정하고 기존 딜레이 작업 취소
                await MainActor.run {
                    isSceneReady = false
                    readyDelayTask?.cancel()
                }
                
                await loadBundleData()
                
                // 로드 완료 후 마지막 상태 저장
                await MainActor.run {
                    lastLoadedKeyrings = bundle.keyrings
                    lastLoadedBackground = bundle.selectedBackground
                    lastLoadedCarabiner = bundle.selectedCarabiner
                }
            }
        }
        .onChange(of: keyringDataList) { oldValue, newValue in            
            // 데이터가 실제로 변경된 경우에만 씬 준비 상태를 false로 설정
            if oldValue != newValue {
                withAnimation(.easeIn(duration: 0.2)) {
                    isSceneReady = false
                }
            }
        }
        .onChange(of: showAlreadyMainBundleToast) { oldValue, newValue in
            if newValue {
                dismissTask?.cancel()
                
                dismissTask = Task {
                    try? await Task.sleep(for: .seconds(1))
                    if !Task.isCancelled {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showAlreadyMainBundleToast = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Data Loading
extension BundleDetailView {
    /// 선택된 뭉치 데이터를 로드하고 뷰 상태를 초기화
    /// 1. 배경 및 카라비너 데이터 로드
    /// 2. 선택된 뭉치의 배경과 카라비너 설정
    /// 3. 선택된 뭉치의 키링들을 Firestore에서 가져와 KeyringData 리스트 생성
    @MainActor
    private func loadBundleData() async {
        print("[BundleDetail] 데이터 로드 시작")
        
        // 1. 배경 및 카라비너 데이터 로드
        await viewModel.loadBackgroundsAndCarabiners()
        
        // 2. 선택된 뭉치의 배경과 카라비너 설정
        guard let bundle = viewModel.selectedBundle else { 
            print("[BundleDetail] 선택된 번들이 없음")
            return 
        }
        viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
        viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)
        
        // 3. 키링 데이터 생성
        guard let carabiner = viewModel.selectedCarabiner else { 
            print("[BundleDetail] 카라비너 데이터가 없음")
            return 
        }
        
        let newKeyringDataList = await viewModel.createKeyringDataList(bundle: bundle, carabiner: carabiner)
        print("[BundleDetail] 생성된 키링 데이터 수: \(newKeyringDataList.count)")
        
        keyringDataList = newKeyringDataList
    }
    
    /// 뭉치 삭제
    @MainActor
    private func deleteBundle() async {
        guard let bundle = viewModel.selectedBundle,
              let documentId = bundle.documentId else {
            showDeleteAlert = false
            return
        }
        
        do {
            // 1. 삭제 확인 Alert 닫기
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDeleteAlert = false
            }
            
            // 2. alert가 확실히 사라지면서 중첩되지 않도록 보장하는 아주 짧은 대기 시간을 줌
            await Task.yield()
            try? await Task.sleep(for: .seconds(0.25))
            
            let db = Firestore.firestore()
            
            // 3. Firebase에서 문서 삭제
            try await db.collection("KeyringBundle").document(documentId).delete()
            
            // 4. 로컬 배열에서도 제거
            viewModel.bundles.removeAll { $0.documentId == documentId }
            
            // 5. 삭제 완료 팝업 표시
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDeleteCompleteToast = true
            }
            
            // 6. 1초 후 팝업 닫고 이전 화면으로 이동
            try? await Task.sleep(for: .seconds(1))
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDeleteCompleteToast = false
            }
            
            // 7. 애니메이션 완료 대기 후 화면 이동
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4초
            
            router.pop()
            
        } catch {
            print("[BundleDetail] 뭉치 삭제 실패: \(error.localizedDescription)")
            showDeleteAlert = false
        }
    }
}

// MARK: - 커스텀 네비게이션 바
extension BundleDetailView {
    private var customnavigationBar: some View {
        CustomNavigationBar {
            //Leading(왼쪽)
            BackToolbarButton {
                router.pop()
            }
        } center: {
            if let bundle = viewModel.selectedBundle {
                Text("\(bundle.name)")
            }
        } trailing: {
            // Trailing (오른쪽)
            MenuToolbarButton {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }
        }
        
    }
}

// MARK: - 메뉴 오버레이
extension BundleDetailView {
    var menuOverlay: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showMenu = false
                    }
                }
            
            if let bundle = viewModel.selectedBundle {
                BundleMenu(
                    position: menuPosition,
                    onNameEdit: {
                        showMenu = false
                        isNavigatingDeeper = true
                        router.push(.bundleNameEditView)
                    },
                    onEdit: {
                        showMenu = false
                        isNavigatingDeeper = true
                        router.push(.bundleEditView)
                    },
                    onDelete: {
                        showMenu = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteAlert = true
                        }
                    },
                    isMain: bundle.isMain
                )
                .zIndex(50)
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
                if let bundle = viewModel.selectedBundle {
                    if bundle.isMain {
                        Text("대표 뭉치 설정 중")
                            .typography(.suit16M)
                            .foregroundStyle(.white100)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
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
    
    private var downloadImageButton: some View {
        Button(action: {
            Task {
                await captureAndSaveScene()
            }
        }) {
            Image(.imageDownload)
        }
        .disabled(isCapturing)
        .frame(width: 48, height: 48)
        .glassEffect(in: .circle)
    }
    
    /// 핀 버튼 - 메인 뭉치 설정/해제
    private var pinButton: some View {
        Group {
            if let bundle = viewModel.selectedBundle {
                if bundle.isMain {
                    Button {
                        showAlreadyMainBundleToast = true
                    } label: {
                        Image(.starFill)
                    }
                    .frame(width: 48, height: 48)
                    .glassEffect(in: .circle)
                } else {
                    // 메인으로 설정되지 않은 경우 버튼으로 표시
                    Button(action: {
                        showChangeMainBundleAlert = true
                    }) {
                        Image(.star)
                    }
                    .frame(width: 48, height: 48)
                    .glassEffect(in: .circle)
                }
            }
        }
    }
    
    //MARK: - 알럿창, 토스트 창
    private var changeMainBundleAlert: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image(.bangMark)
                    .padding(.vertical, 4)
                
                Text("대표 뭉치를 변경할까요?")
                    .typography(.suit20B)
                    .foregroundStyle(.black100)
                Text("선택한 뭉치가 홈에 걸려요.")
                    .typography(.suit15R)
                    .foregroundStyle(.black100)
            }
            .padding(8)
            
            // 버튼 영역
            HStack(spacing: 16) {
                Button {
                    showChangeMainBundleAlert = false
                } label: {
                    Text("취소")
                        .typography(.suit17SB)
                        .foregroundStyle(.black100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.black10)
                
                Button {
                    viewModel.updateBundleMainStatus(bundle: viewModel.selectedBundle!, isMain: true) { _ in }
                    showChangeMainBundleAlert = false
                    isMainBundleChange = true
                } label: {
                    Text("확인")
                        .typography(.suit17SB)
                        .foregroundStyle(.white100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.main500)
            }
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 34))
        .frame(maxWidth: .infinity)
    }
    
    private var alreadyMainBundleToast: some View {
        Text("이미 대표 뭉치로 설정되어 있어요")
            .typography(.suit17SB)
            .foregroundColor(.black100)
            .frame(maxWidth: .infinity)
            .frame(height: 73)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
            .transition(.scale.combined(with: .opacity))
    }
}

