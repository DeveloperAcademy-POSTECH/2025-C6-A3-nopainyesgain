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
    
    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []
    
    /// 씬 준비 완료 여부
    @State private var isSceneReady = false
    
    /// 마지막으로 로드된 번들의 키링 배열 (변경 감지용)
    @State private var lastLoadedKeyrings: [String] = []
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ZStack(alignment: .top) {
                    if let bundle = viewModel.selectedBundle,
                       let carabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner),
                       let background = viewModel.selectedBackground,
                       !keyringDataList.isEmpty {  // 키링 데이터가 있을 때만 씬 생성
                        
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
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isSceneReady = true
                                }
                            }
                        )
                        .animation(.easeInOut(duration: 0.3), value: isSceneReady)
                        /// 씬 재생성 조건을 위한 ID 설정
                        /// 배경, 카라비너, 키링 구성이 변경되면 씬을 완전히 재생성
                        .id("\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map(\.index).sorted())")
                        
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
                    
                    if let bundle = viewModel.selectedBundle {
                        DeletePopup(
                            title: "\(bundle.name)\n삭제하시겠어요?",
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
                        .opacity(showDeleteAlert ? 1 : 0)
                        .position(x: screenWidth/2, y: screenHeight/2)
                        .zIndex(200)
                    }
                    
                    DeleteCompletePopup(isPresented: $showDeleteCompleteToast)
                        .opacity(showDeleteCompleteToast ? 1 : 0)
                        .zIndex(200)
                        .position(x: screenWidth/2, y: screenHeight/2)
                    
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
        }
        .onDisappear {
            // Alert/Toast 상태 초기화
            showDeleteCompleteToast = false
            showAlreadyMainBundleToast = false
            showChangeMainBundleAlert = false
            isMainBundleChange = false
            showDeleteAlert = false
            showMenu = false
        }
        .task(id: viewModel.selectedBundle?.keyrings) {
            guard let bundle = viewModel.selectedBundle else {
                return
            }
            
            // 번들의 키링 배열이 변경되었는지 확인
            let hasChanged = bundle.keyrings != lastLoadedKeyrings
            
            // 최초 로드이거나 데이터가 변경된 경우에만 로드
            if (keyringDataList.isEmpty || hasChanged) {
                await loadBundleData()
                
                // 로드 완료 후 마지막 상태 저장
                await MainActor.run {
                    lastLoadedKeyrings = bundle.keyrings
                }
            }
        }
        .onChange(of: keyringDataList) { oldValue, newValue in
            
            // 최초 로드 시에만 초기화 (빈 배열 → 데이터 있음)
            if oldValue.isEmpty && !newValue.isEmpty {
                withAnimation(.easeIn(duration: 0.2)) {
                    isSceneReady = false
                }
            } else if !oldValue.isEmpty && !newValue.isEmpty {
                withAnimation(.easeIn(duration: 0.2)) {
                    isSceneReady = false
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
        // 1. 배경 및 카라비너 데이터 로드
        await viewModel.loadBackgroundsAndCarabiners()
        
        // 2. 선택된 뭉치의 배경과 카라비너 설정
        guard let bundle = viewModel.selectedBundle else { return }
        viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
        viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)
        
        // 3. 키링 데이터 생성
        guard let carabiner = viewModel.selectedCarabiner else { return }
        keyringDataList = await viewModel.createKeyringDataList(bundle: bundle, carabiner: carabiner)
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
            
            // 2. Alert 닫힘 애니메이션 완료 대기
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4초
            
            let db = Firestore.firestore()
            
            // 3. Firebase에서 문서 삭제
            try await db.collection("KeyringBundle").document(documentId).delete()
            
            // 4. 로컬 배열에서도 제거
            viewModel.bundles.removeAll { $0.documentId == documentId }
            
            // 5. 삭제 완료 팝업 표시
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDeleteCompleteToast = true
            }
            
            // 6. 2초 후 팝업 닫고 이전 화면으로 이동
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초
            
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
                Image("bangMark")
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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAlreadyMainBundleToast = false
                    }
                }
            }
    }
}
