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
    @State var showMenu: Bool = false
    @State var showDeleteAlert: Bool = false
    @State var showDeleteCompleteToast: Bool = false
    @State var showAlreadyMainBundleToast: Bool = false
    @State var showChangeMainBundleAlert: Bool = false
    @State var isMainBundleChange: Bool = false
    @State var isCapturing: Bool = false
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
                                            viewModel.updateLastConfigIds(
                                                background: viewModel.selectedBackground,
                                                carabiner: viewModel.selectedCarabiner,
                                                keyringDataList: keyringDataList
                                            )
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
        // 변경: 이전 화면에서 전달된 구성 id를 뷰모델에게 확인하여 동일 구성이라면 즉시 준비 완료 복구
        .task {
            let skip = viewModel.shouldSkipReloadForReturnedConfig()
            if skip {
                // 동일 구성 스킵 시, Scene이 바로 그려질 수 있도록 최소 resolve 보장
                if viewModel.selectedBackground == nil, let b = viewModel.selectedBundle {
                    viewModel.selectedBackground = viewModel.resolveBackground(from: b.selectedBackground)
                }
                if viewModel.selectedCarabiner == nil, let b = viewModel.selectedBundle {
                    viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: b.selectedCarabiner)
                }
                if !isSceneReady {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isSceneReady = true
                    }
                }
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
            
            // 진행 중인 작업들 취소
            readyDelayTask?.cancel()
            dismissTask?.cancel()
        }
        .task(id: "\(viewModel.selectedBundle?.keyrings ?? [])_\(viewModel.selectedBundle?.selectedBackground ?? "")_\(viewModel.selectedBundle?.selectedCarabiner ?? "")") {
            guard let bundle = viewModel.selectedBundle else {
                return
            }

            // 1) 동일 구성인지 먼저 확인(+변경 감지)
            let skip = viewModel.shouldSkipReloadForReturnedConfig()
            if skip {
                // 동일 구성: 리로드 스킵 및 필요 시 즉시 준비 완료 복구
                // Scene이 바로 그려질 수 있도록 최소 resolve 보장
                if viewModel.selectedBackground == nil {
                    viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
                }
                if viewModel.selectedCarabiner == nil {
                    viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)
                }
                return
            }
            // 스킵이 아니면 항상 로드 (최초/변경 모두 커버)
            await MainActor.run {
                isSceneReady = true
                readyDelayTask?.cancel()
            }
            
            await loadBundleData()
        }
        .onChange(of: keyringDataList) { oldValue, newValue in
            let oldId = viewModel.makeKeyringsId(oldValue)
            let newId = viewModel.makeKeyringsId(newValue)
            if oldId != newId {
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
        
        // 1. 배경 및 카라비너 데이터 로드
        await viewModel.loadBackgroundsAndCarabiners()
        
        // 2. 선택된 뭉치의 배경과 카라비너 설정
        guard let bundle = viewModel.selectedBundle else {
            // 데이터가 없으면 오버레이가 영원히 남지 않도록 최소 복구
            isSceneReady = true
            return
        }
        viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
        viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)
        
        // 3. 키링 데이터 생성
        guard let carabiner = viewModel.selectedCarabiner else {
            // 카라비너 resolve 실패 시에도 최소 복구
            isSceneReady = true
            return
        }

        let newKeyringDataList = await viewModel.createKeyringDataList(bundle: bundle, carabiner: carabiner)
        keyringDataList = newKeyringDataList
    }
    
    /// 뭉치 삭제
    @MainActor
    func deleteBundle() async {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            showDeleteAlert = false
            ToastManager.shared.show()
            return
        }

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
            BackToolbarButton {
                router.pop()
            }
        } center: {
            if let bundle = viewModel.selectedBundle {
                Text("\(bundle.name)")
            }
        } trailing: {
            MenuToolbarButton {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
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
                
                if let bundle = viewModel.selectedBundle {
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
                        // 네트워크 체크
                        guard NetworkManager.shared.isConnected else {
                            ToastManager.shared.show()
                            return
                        }

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
    
    /// 이미지 다운로드 버튼
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
}
