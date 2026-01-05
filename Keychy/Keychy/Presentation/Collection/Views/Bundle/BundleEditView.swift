//
//  BundleEditView.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI
import NukeUI
import SceneKit
import FirebaseFirestore

struct BundleEditView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var viewModel: CollectionViewModel
    
    @State private var isSceneReady = false
    
    @State private var selectedCategory: String = ""
    @State private var selectedKeyringPosition: Int = 0
    @State private var newSelectedBackground: BackgroundViewData?
    // 선택한 카라비너는 확인 알럿 후에만 바뀜
    @State private var selectCarabiner: CarabinerViewData?
    @State private var newSelectedCarabiner: CarabinerViewData?
    
    // 배경, 카라비너 선택 시트 활성화/비활성화
    @State private var showBackgroundSheet: Bool = false
    @State private var showCarabinerSheet: Bool = false
    // 카라비너 변경 확인 알러트 ('카라비너 변경 시 키링은 모두 초기화됩니다')
    @State private var showChangeCarabinerAlert: Bool = false
    // 시트 높이 (화면의 약 43%에 해당)
    @State private var sheetHeight: CGFloat = 360
    
    // 구매 시트
    @State var showPurchaseSheet = false
    
    // 구매 처리 상태
    @State private var isPurchasing = false
    
    // 구매 Alert 애니메이션
    @State var showPurchaseSuccessAlert = false
    @State var purchasesSuccessScale: CGFloat = 0.3
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3
    
    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []
    
    // 키링 편집 관련 상태
    @State private var showSelectKeyringSheet = false
    @State private var selectedKeyrings: [Int: Keyring] = [:]
    @State private var keyringOrder: [Int] = []
    @State private var selectedPosition = 0
    @State private var sceneRefreshId = UUID()
    @State private var isNavigatingAway = false // 화면 전환 중인지 추적
    
    // 공통 그리드 컬럼 (배경, 카라비너, 키링 모두 동일)
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    private let sheetHeightRatio: CGFloat = 0.43
    
    var body: some View {
        ZStack(alignment: .bottom) {
            mainContentView
                .blur(radius: showPurchaseSuccessAlert ? 15 : 0)
            
            loadingOverlay
            
            // 키링 선택 시트
            keyringSheetOverlay
                .blur(radius: showPurchaseSuccessAlert ? 15 : 0)
            
            // 배경, 카라비너 선택 시트
            sheetContent()
                .blur(radius: showPurchaseSuccessAlert ? 15 : 0)
            
            // Alert들, 컨텐츠가 화면의 중앙에 오도록 함
            alertContent
                .position(x: screenWidth / 2, y: screenHeight / 2)
            
        }
        .sheet(isPresented: $showPurchaseSheet) {
            purchaseSheetView
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .withToast(position: .default)
        .task {
            // 화면 전환 중이면 초기화 건너뛰기
            guard !isNavigatingAway else {
                return
            }
            await initializeData()
        }
        .onAppear {
            // 화면이 나타날 때마다 데이터 새로고침
            Task {
                await refreshEditData()
            }
            viewModel.hideTabBar()
            // 화면 첫 진입 시 배경 시트를 보여줌
            if !showBackgroundSheet && !showCarabinerSheet {
                showBackgroundSheet = true
            }
        }
        .onDisappear {
            isNavigatingAway = false
        }
        .ignoresSafeArea()
        // 배경 시트와 카라비너 시트는 동시에 열릴 수 없음 (하나가 열리면 다른 하나는 자동으로 닫힘)
        .onChange(of: showBackgroundSheet) { oldValue, newValue in
            if newValue {
                showCarabinerSheet = false
            }
        }
        .onChange(of: showCarabinerSheet) { oldValue, newValue in
            if newValue {
                showBackgroundSheet = false
            }
        }
        .onChange(of: newSelectedBackground) { _, newBackground in
            guard newBackground != nil else { return }
            // 배경 변경 시에는 키링 데이터 업데이트만 수행 (Firebase 접근 없음)
            updateKeyringDataList()
        }
        .onChange(of: newSelectedCarabiner) { _, newCarabiner in
            guard newCarabiner != nil else { return }
            // 카라비너 변경 시에는 키링 데이터 업데이트만 수행 (Firebase 접근 없음)
            updateKeyringDataList()
        }
        // 키링 선택 시트 활성화 시 배경, 카라비너 선택 시트의 높이를 낮춤
        .onChange(of: showSelectKeyringSheet) { _, newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if newValue {
                    sheetHeight = screenHeight * 0.08
                }
            }
        }
    }
    
    // MARK: - Main Content Views
    
    /// 메인 콘텐츠 영역 (배경, 씬, 네비게이션 바)
    private var mainContentView: some View {
        ZStack {
            sceneContentView
            
            // navigationBar
            customNavigationBar
        }
        .blur(radius: isSceneReady ? 0 : 15)
    }
    
    /// 씬 콘텐츠 (MultiKeyringScene 또는 placeholder 이미지)
    private var sceneContentView: some View {
        Group {
            if let bundle = viewModel.selectedBundle,
               let background = newSelectedBackground,
               let carabiner = newSelectedCarabiner {
                
                keyringEditSceneView(bundle: bundle, background: background, carabiner: carabiner)
                
            } else {
                placeholderImageView
            }
        }
    }
    
    /// Placeholder 이미지 뷰 (데이터 로드 전)
    private var placeholderImageView: some View {
        ZStack {
            if let bg = newSelectedBackground {
                LazyImage(url: URL(string: bg.background.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.isLoading {
                        Color.black20
                            .ignoresSafeArea()
                    }
                }
            }
            if let cb = newSelectedCarabiner {
                VStack {
                    LazyImage(url: URL(string: cb.carabiner.carabinerImage[0])) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    Spacer()
                }
            }
        }
    }
    
    /// 로딩 오버레이
    private var loadingOverlay: some View {
        Group {
            if !isSceneReady && !isNavigatingAway {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(100)
                LoadingAlert(type: .longWithKeychy, message: "키링 뭉치를 불러오고 있어요")
                    .zIndex(101)
            }
        }
    }
    
    /// 키링 선택 시트 오버레이
    private var keyringSheetOverlay: some View {
        Group {
            if showSelectKeyringSheet {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(1)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showSelectKeyringSheet = false
                        }
                    }
                keyringSelectionSheet()
            }
        }
    }
    
    // MARK: - 키링 편집 뷰 컴포넌트들
    
    /// 키링 편집 씬 뷰
    private func keyringEditSceneView(bundle: KeyringBundle, background: BackgroundViewData, carabiner: CarabinerViewData) -> some View {
        ZStack(alignment: .top) {
            // MultiKeyringScene
            MultiKeyringSceneView(
                keyringDataList: keyringDataList,
                ringType: .basic,
                chainType: .basic,
                backgroundColor: .clear,
                backgroundImageURL: background.background.backgroundImage,
                carabinerBackImageURL: carabiner.carabiner.backImageURL,
                carabinerFrontImageURL: carabiner.carabiner.frontImageURL,
                carabinerX: carabiner.carabiner.carabinerX,
                carabinerY: carabiner.carabiner.carabinerY,
                carabinerWidth: carabiner.carabiner.carabinerWidth,
                currentCarabinerType: carabiner.carabiner.type,
                onAllKeyringsReady: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isSceneReady = true
                    }
                }
            )
            .ignoresSafeArea()
            .blur(radius: isSceneReady ? 0 : 10)
            .animation(.easeInOut(duration: 0.3), value: isSceneReady)
            .id("scene_\(background.background.id ?? "bg")_\(carabiner.carabiner.id ?? "cb")_\(keyringDataList.count)_\(sceneRefreshId.uuidString)")
            
            // 키링 추가 버튼들
            GeometryReader { geometry in
                let sceneWidth: CGFloat = 402
                let sceneHeight: CGFloat = 874
                
                // 실제 화면 크기에 맞게 씬을 스케일링 하는 비율 계산
                let scale = max(geometry.size.width / sceneWidth, geometry.size.height / sceneHeight)
                
                // 스케일 적용 후 콘텐츠 크기
                let contentW = sceneWidth * scale
                let contentH = sceneHeight * scale
                
                // 씬을 화면 중앙에 배치하기 위한 오프셋 (실제 뷰 크기와 스케일 된 씬의 크기 차이를 균등하게 배분)
                let dx = (geometry.size.width - contentW) / 2
                let dy = (geometry.size.height - contentH) / 2
                
                ForEach(0..<carabiner.carabiner.maxKeyringCount, id: \.self) { index in
                    // 씬 좌표를 실제 화면 좌표로 변환 (오프셋 + 스케일 적용)
                    let viewX = dx + carabiner.carabiner.keyringXPosition[index] * scale
                    let viewY = dy + carabiner.carabiner.keyringYPosition[index] * scale
                    
                    CarabinerAddKeyringButton(
                        isSelected: selectedPosition == index,
                        action: {
                            selectedPosition = index
                            withAnimation(.easeInOut) {
                                showSelectKeyringSheet = true
                            }
                        }
                    )
                    .position(x: viewX, y: viewY)
                    .opacity(showSelectKeyringSheet && selectedPosition != index ? 0.3 : 1.0)
                    .zIndex(selectedPosition == index ? 100 : 1) // 선택된 버튼이 dim 오버레이(zIndex 1) 위로 오도록
                    .opacity(isSceneReady ? 1.0 : 0.0) // LoadingAlert가 표시될 때는 버튼 숨김
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
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
                        ForEach(viewModel.sortedKeyringsForSelection(selectedKeyrings: selectedKeyrings, selectedPosition: selectedPosition), id: \.self) { keyring in
                            keyringCell(keyring: keyring)
                        }
                    }
                }
            }
            
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 0, trailing: 20))
        .frame(maxWidth: .infinity)
        .frame(height: screenHeight * sheetHeightRatio)
        .glassEffect(.regular, in: .rect)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
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
                withAnimation(.easeInOut) {
                    showSelectKeyringSheet = false
                }
            } else if !isSelectedElsewhere {
                // 중복이 아닐 때만 선택 가능
                // 기존 있으면 순서 제거 후 교체
                if selectedKeyrings[selectedPosition] != nil {
                    keyringOrder.removeAll { $0 == selectedPosition }
                }
                selectedKeyrings[selectedPosition] = keyring
                keyringOrder.append(selectedPosition)
                withAnimation(.easeInOut) {
                    showSelectKeyringSheet = false
                }
            }
            // 중복인 경우 아무것도 하지 않음 (선택되지 않음)
            updateKeyringDataList()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 10) {
                    ZStack {
                        CollectionCellView(keyring: keyring)
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                            .cornerRadius(10)
                        
                        // 외곽선을 별도 레이어로 그리기
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelectedHere ? .mainOpacity80 : .clear, lineWidth: 1.8)
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                        
                        // 다른 위치에 장착된 경우 오버레이
                        if isSelectedElsewhere {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black50)
                                .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                        }
                    }
                    
                    Text("\(keyring.name)")
                        .typography(isSelectedHere ? .notosans14SB : .notosans14M)
                        .foregroundStyle(isSelectedHere ? .main500 :  .black100)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                // 장착 중 아이콘
                if isSelectedElsewhere || isSelectedHere {
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
    
    /// 배경/카라비너 시트 컨텐츠
    private func sheetContent() -> some View {
        Group {
            // 배경 시트
            if showBackgroundSheet {
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 8) {
                        editBackgroundButton
                        editCarabinerButton
                        Spacer()
                    }
                    .padding(.leading, 18)
                    .padding(.bottom, 10)
                    BundleItemCustomSheet(
                        sheetHeight: $sheetHeight,
                        content: SelectBackgroundSheet(
                            viewModel: viewModel,
                            selectedBG: newSelectedBackground,
                            onBackgroundTap: { bg in
                                newSelectedBackground = bg
                            }
                        )
                    )
                }
            }
            
            // 카라비너 시트
            if showCarabinerSheet {
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 8) {
                        editBackgroundButton
                        editCarabinerButton
                        Spacer()
                    }
                    .padding(.leading, 18)
                    .padding(.bottom, 10)
                    BundleItemCustomSheet(
                        sheetHeight: $sheetHeight,
                        content: SelectCarabinerSheet(
                            viewModel: viewModel,
                            selectedCarabiner: newSelectedCarabiner,
                            onCarabinerTap: { carabiner in
                                selectCarabiner = carabiner
                                showChangeCarabinerAlert = true
                            }
                        )
                    )
                }
            }
        }
    }
    
    /// Alert 컨텐츠들
    private var alertContent: some View {
        Group {
            if showChangeCarabinerAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showChangeCarabinerAlert = false
                        }
                    }
                VStack {
                    Spacer()
                    CarabinerChangePopup(
                        title: "카라비너를 변경하시겠어요?",
                        message: "새 카라비너로 변경하면\n현재 뭉치에 걸린 키링들이 모두 해제돼요.",
                        onCancel: {
                            selectCarabiner = nil
                            showChangeCarabinerAlert = false
                        },
                        onConfirm: {
                            Task { @MainActor in
                                // 편집 중 로컬 상태만 변경 (Firestore에 쓰지 않음)
                                
                                // 1) UI 오버레이/선택 상태 초기화
                                selectedPosition = 0
                                
                                // 2) 키링 데이터와 선택 목록을 즉시 비우기
                                keyringDataList = []
                                selectedKeyrings.removeAll()
                                keyringOrder.removeAll()
                                
                                // 3) 새 카라비너 적용
                                newSelectedCarabiner = selectCarabiner
                                
                                // 4) 빈 상태를 씬/리스트에 반영
                                updateKeyringDataList()
                                
                                // 5) 씬 강제 리프레시로 남은 잔상 제거
                                sceneRefreshId = UUID()
                                
                                // 6) 알럿 닫기
                                showChangeCarabinerAlert = false
                            }
                        }
                    )
                    .padding(.horizontal, 51)
                    Spacer()
                }
            }
            
            // 구매 성공 Alert
            if showPurchaseSuccessAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        Task {
                            await saveBundleChanges()
                            await MainActor.run {
                                showPurchaseSuccessAlert = false
                                purchasesSuccessScale = 0.3
                            }
                        }
                    }
                
                KeychyAlert(type: .checkmark, message: "구매가 완료되었어요!", isPresented: $showPurchaseSuccessAlert)
                    .zIndex(101)
            }
            
            // 구매 실패 Alert
            if showPurchaseFailAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        showPurchaseFailAlert = false
                        purchaseFailScale = 0.3
                    }
                
                PurchaseFailAlert(
                    checkmarkScale: purchaseFailScale,
                    onCancel: {
                        showPurchaseFailAlert = false
                        purchaseFailScale = 0.3
                    },
                    onCharge: {
                        showPurchaseFailAlert = false
                        purchaseFailScale = 0.3
                        saveCurrentSelection()
                        router.push(.coinCharge)
                    }
                )
                .padding(.horizontal, 51)
            }
        }
    }
    
    // MARK: - 데이터 로딩 및 초기화
    
    /// 초기 데이터 로딩
    private func initializeData() async {
        
        // 데이터를 새로 로드하므로 씬도 새로 로드됨
        await MainActor.run {
            isSceneReady = false
        }
        
        // 사용자 키링 데이터 로드
        let uid = UserManager.shared.userUID
        await withCheckedContinuation { continuation in
            viewModel.fetchUserKeyrings(uid: uid) { success in
                continuation.resume()
            }
        }
        
        // 배경/카라비너 데이터 로드
        await withCheckedContinuation { continuation in
            viewModel.fetchAllBackgrounds { _ in
                if let selectedBundle = viewModel.selectedBundle {
                    if self.newSelectedBackground == nil {
                        self.newSelectedBackground = viewModel.backgroundViewData.first { bgData in
                            bgData.background.id == selectedBundle.selectedBackground
                        }
                    }
                }
                self.restoreBackgroundSelection()
                
                viewModel.fetchAllCarabiners { _ in
                    if let selectedBundle = viewModel.selectedBundle {
                        if self.newSelectedCarabiner == nil {
                            self.newSelectedCarabiner = viewModel.carabinerViewData.first { cbData in
                                cbData.carabiner.id == selectedBundle.selectedCarabiner
                            }
                        }
                    }
                    self.restoreCarabinerSelection()
                    
                    Task {
                        // Firebase 데이터를 한 번만 로컬 상태로 초기화
                        await self.initializeSelectedKeyringsFromFirebase()
                        // 이후부터는 완전히 로컬 데이터만 사용
                        self.updateKeyringDataList()
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    /// 화면이 다시 나타날 때 데이터 새로고침 (구매 상태 업데이트)
    private func refreshEditData() async {
        // 현재 선택된 아이템의 ID 저장
        let currentBackgroundId = newSelectedBackground?.background.id
        let currentCarabinerId = newSelectedCarabiner?.carabiner.id
        
        // 배경 데이터 새로고침
        await withCheckedContinuation { continuation in
            viewModel.fetchAllBackgrounds { _ in
                // 이전에 선택했던 배경을 다시 찾아서 선택 (구매 상태가 업데이트됨)
                if let bgId = currentBackgroundId {
                    self.newSelectedBackground = viewModel.backgroundViewData.first { $0.background.id == bgId }
                }
                continuation.resume()
            }
        }
        
        // 카라비너 데이터 새로고침
        await withCheckedContinuation { continuation in
            viewModel.fetchAllCarabiners { _ in
                // 이전에 선택했던 카라비너를 다시 찾아서 선택 (구매 상태가 업데이트됨)
                if let cbId = currentCarabinerId {
                    self.newSelectedCarabiner = viewModel.carabinerViewData.first { $0.carabiner.id == cbId }
                }
                continuation.resume()
            }
        }
        
        // 키링 데이터도 새로고침
        let uid = UserManager.shared.userUID
        await withCheckedContinuation { continuation in
            viewModel.fetchUserKeyrings(uid: uid) { success in
                continuation.resume()
            }
        }
    }
    
    /// Firebase 데이터를 로컬 상태로 한 번만 초기화
    private func initializeSelectedKeyringsFromFirebase() async {
        guard let bundle = viewModel.selectedBundle else {
            return
        }
        
        let result = await viewModel.convertBundleToSelectedKeyrings(bundle: bundle)
        selectedKeyrings = result.0
        keyringOrder = result.1
    }
    
    /// 키링 데이터 리스트 업데이트
    private func updateKeyringDataList() {
        guard let carabiner = newSelectedCarabiner?.carabiner else {
            keyringDataList = []
            return
        }
        
        let newData = viewModel.createKeyringDataListFromSelected(
            selectedKeyrings: selectedKeyrings,
            keyringOrder: keyringOrder,
            carabiner: carabiner
        )
        
        // 데이터가 실제로 변경된 경우에만 업데이트
        if keyringDataList != newData {
            keyringDataList = newData
            
            // 키링이 추가/변경될 때도 씬을 새로고침하여 확실히 반영되도록 함
            if !newData.isEmpty {
                sceneRefreshId = UUID()
            }
        }
    }
    
    /// 최종 뭉치 변경사항을 Firebase에 저장
    private func saveBundleChanges() async {
        
        guard let bundle = viewModel.selectedBundle,
              let documentId = bundle.documentId,
              let background = newSelectedBackground,
              let carabiner = newSelectedCarabiner else {
            return
        }
        
        // ID 안전성 체크
        guard let backgroundId = background.background.id,
              let carabinerId = carabiner.carabiner.id else {
            return
        }
        
        // 변경사항 체크: 원본 번들과 현재 선택된 항목 비교
        let isBackgroundChanged = bundle.selectedBackground != backgroundId
        let isCarabinerChanged = bundle.selectedCarabiner != carabinerId
        
        // 키링 변경사항 체크
        let currentKeyrings = viewModel.convertSelectedKeyringsToBundleFormat(
            selectedKeyrings: selectedKeyrings,
            maxKeyringCount: carabiner.carabiner.maxKeyringCount
        ).map { $0.isEmpty ? "none" : $0 }
        
        let isKeyringsChanged = bundle.keyrings != currentKeyrings
        
        // 변경사항이 전혀 없으면 저장하지 않고 즉시 리턴
        if !isBackgroundChanged && !isCarabinerChanged && !isKeyringsChanged {
            return
        }
        
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let updateData: [String: Any] = [
                "keyrings": currentKeyrings,
                "selectedBackground": backgroundId,
                "selectedCarabiner": carabinerId
            ]
            try await db.collection("KeyringBundle").document(documentId).updateData(updateData)
            
            // 로컬 상태도 업데이트
            await MainActor.run {
                if let index = viewModel.bundles.firstIndex(where: { $0.documentId == documentId }) {
                    viewModel.bundles[index].keyrings = currentKeyrings
                    viewModel.bundles[index].selectedBackground = backgroundId
                    viewModel.bundles[index].selectedCarabiner = carabinerId
                }
                
                // selectedBundle도 업데이트
                if viewModel.selectedBundle?.documentId == documentId {
                    viewModel.selectedBundle?.keyrings = currentKeyrings
                    viewModel.selectedBundle?.selectedBackground = backgroundId
                    viewModel.selectedBundle?.selectedCarabiner = carabinerId
                }
                
                // 캐시 삭제, BundleInventoryView로 접근했을 때 썸네일 업데이트 하도록 함
                BundleImageCache.shared.delete(for: documentId)
            }
        } catch {
            print("❌ Firebase 업데이트 실패: \(error.localizedDescription)")
            if let firestoreError = error as NSError? {
                print("Firebase 에러 코드: \(firestoreError.code)")
                print("Firebase 에러 도메인: \(firestoreError.domain)")
                print("Firebase 에러 상세: \(firestoreError.userInfo)")
            }
        }
    }
    
    // MARK: - 선택 상태 저장/복원
    private func saveCurrentSelection() {
        if let bg = newSelectedBackground {
            UserDefaults.standard.set(bg.background.id, forKey: "tempSelectedBackgroundId")
        }
        if let cb = newSelectedCarabiner {
            UserDefaults.standard.set(cb.carabiner.id, forKey: "tempSelectedCarabinerId")
        }
    }
    
    private func restoreSelection() {
        restoreBackgroundSelection()
        restoreCarabinerSelection()
    }
    
    private func restoreBackgroundSelection() {
        if let savedBackgroundId = UserDefaults.standard.string(forKey: "tempSelectedBackgroundId") {
            if let restoredBackground = viewModel.backgroundViewData.first(where: { $0.background.id == savedBackgroundId }) {
                newSelectedBackground = restoredBackground
                // 복원 후 삭제
                UserDefaults.standard.removeObject(forKey: "tempSelectedBackgroundId")
            }
        }
    }
    
    private func restoreCarabinerSelection() {
        if let savedCarbinerId = UserDefaults.standard.string(forKey: "tempSelectedCarabinerId") {
            if let restoredCarabiner = viewModel.carabinerViewData.first(where: { $0.carabiner.id == savedCarbinerId }) {
                newSelectedCarabiner = restoredCarabiner
                // 복원 후 삭제
                UserDefaults.standard.removeObject(forKey: "tempSelectedCarabinerId")
            }
        }
    }
}

//MARK: - 툴바
extension BundleEditView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                isNavigatingAway = true
                router.pop()
            }
        } center: {
        } trailing: {
            let hasPayableItems = (newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) || (newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0)
            
            if hasPayableItems {
                let payableCount = ((newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) ? 1 : 0) + ((newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0) ? 1 : 0)
                PurchaseToolbarButton(title: "구매 \(payableCount)") {
                    showPurchaseSheet = true
                }
            } else {
                TextToolbarButton(title: "완료") {
                    // 네트워크 체크
                    guard NetworkManager.shared.isConnected else {
                        ToastManager.shared.show()
                        return
                    }

                    Task {
                        await MainActor.run {
                            // pop 전에 현재 구성 id를 ViewModel에 저장
                            let bgId = viewModel.makeBackgroundId(newSelectedBackground?.background ?? viewModel.resolveBackground(from: viewModel.selectedBundle?.selectedBackground ?? ""))
                            let cbId = viewModel.makeCarabinerId(newSelectedCarabiner?.carabiner ?? viewModel.resolveCarabiner(from: viewModel.selectedBundle?.selectedCarabiner ?? ""))
                            
                            // 편집 중 키링 데이터 기준으로 keyringsId 생성
                            let currentKeyringDataList = keyringDataList
                            let krId = viewModel.makeKeyringsId(currentKeyringDataList)
                            
                            viewModel.returnBackgroundId = bgId
                            viewModel.returnCarabinerId = cbId
                            viewModel.returnKeyringsId = krId
                            
                            // 화면 전환 시작 플래그
                            isNavigatingAway = true
                        }

                        // 상태 변경이 UI에 반영되도록 짧은 대기
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
                        await saveBundleChanges()

                        await MainActor.run {
                            router.pop()
                        }
                    }
                }
            }
        }
    }
}

//MARK: - 배경, 카라비너 시트 여는 버튼
extension BundleEditView {
    private var editBackgroundButton: some View {
        Button {
            // 배경 시트 열기
            showBackgroundSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showBackgroundSheet ? .backgroundIconWhite100 : .backgroundIconGray600)
                Text("배경")
                    .typography(.suit9SB)
                    .foregroundStyle(showBackgroundSheet ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(showBackgroundSheet ? .main500 : .white100)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var editCarabinerButton: some View {
        Button {
            // 카라비너 시트 열기
            showCarabinerSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showCarabinerSheet ? .carabinerIconWhite100 : .carabinerIconGray600)
                Text("카라비너")
                    .typography(.suit9SB)
                    .foregroundStyle(showCarabinerSheet ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(showCarabinerSheet ? .main500 : .white100)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 구매 처리 관련
extension BundleEditView {
    private var purchaseSheetView: some View {
        VStack(spacing: 12) {
            // 상단 섹션 - 닫기 버튼, 타이틀
            HStack {
                Button {
                    showPurchaseSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray600)
                }
                Spacer()
                Text("구매하기")
                    .typography(.suit17B)
                    .foregroundStyle(.gray600)
                Spacer()
            }
            .padding(EdgeInsets(top: 30, leading: 20, bottom: 10, trailing: 20))
            
            // 구매할 아이템 목록
            ScrollView {
                VStack(spacing: 20) {
                    if let bg = newSelectedBackground, !bg.isOwned && bg.background.price > 0 {
                        cartItemRow(name: bg.background.backgroundName, type: "배경", price: bg.background.price)
                    }
                    if let cb = newSelectedCarabiner, !cb.isOwned && cb.carabiner.price > 0 {
                        cartItemRow(name: cb.carabiner.carabinerName, type: "카라비너", price: cb.carabiner.price)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // 내 보유 재화와 총 가격
            HStack(spacing: 6) {
                Text("내 보유 : ")
                    .typography(.suit15M25)
                    .foregroundStyle(.black100)
                    .padding(.vertical, 4.5)
                Text("\(UserManager.shared.currentUser?.coin ?? 0)")
                    .typography(.nanum16EB)
                    .foregroundStyle(.main500)
            }
            purchaseButton
                .padding(.horizontal, 33.2)
                .adaptiveBottomPadding()
        }
        .background(.white100)
        .presentationDetents([.fraction(0.43)])
    }
    
    private func cartItemRow(name: String, type: String, price: Int) -> some View {
        HStack(spacing: 6) {
            Image(.selectedIcon)
            
            Text(name)
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.trailing, 7)
            
            Text(type)
                .typography(.suit13M)
                .foregroundStyle(.gray400)
            
            Spacer()
            
            Text("\(price)")
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray50)
        )
    }
    
    // 구매 버튼, PurchaseManager로 통합한 후에 공통 컴포넌트로 빼야 할 듯.
    private var purchaseButton: some View {
        Button {
            Task {
                await purchaseItems()
            }
        } label: {
            HStack(spacing: 5) {
                if isPurchasing {
                    LoadingAlert(type: .short, message: nil)
                        .scaleEffect(0.8)
                } else {
                    Image(.purchaseSheet)
                }
                
                Text("\(totalCartPrice)")
                    .typography(.nanum18EB)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                Text("(\(payableItemsCount)개)")
                    .typography(.suit17SB)
            }
            .foregroundStyle(.white100)
            .frame(maxWidth: .infinity)
            .background(isPurchasing ? .gray400 : .black80)
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
        .disabled(isPurchasing)
    }
    
    var payableItemsCount: Int {
        let backgroundCount = (newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) ? 1 : 0
        let carabinerCount = (newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0) ? 1 : 0
        return backgroundCount + carabinerCount
    }
    
    var totalCartPrice: Int {
        let backgroundPrice = (newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) ? newSelectedBackground!.background.price : 0
        let carabinerPrice = (newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0) ? newSelectedCarabiner!.carabiner.price : 0
        return backgroundPrice + carabinerPrice
    }
    
    // MARK: - 구매 처리
    private func purchaseItems() async {
        isPurchasing = true
        
        var allSuccess = true
        
        // 선택된 배경이 유료인 경우 구매
        if let bg = newSelectedBackground, !bg.isOwned && bg.background.price > 0 {
            let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(bg.background, userManager: UserManager.shared)
            
            switch result {
            case .success:
                break
            case .insufficientCoins, .failed(_):
                allSuccess = false
            }
        }
        
        // 선택된 카라비너가 유료이고 이전 구매가 성공한 경우에만 구매
        if allSuccess, let cb = newSelectedCarabiner, !cb.isOwned && cb.carabiner.price > 0 {
            let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(cb.carabiner, userManager: UserManager.shared)
            
            switch result {
            case .success:
                break
            case .insufficientCoins, .failed(_):
                allSuccess = false
            }
        }
        
        if allSuccess {
            // 모든 구매 성공 - alert만 표시
            await MainActor.run {
                isPurchasing = false
                showPurchaseSheet = false
                showPurchaseSuccessAlert = true
                purchasesSuccessScale = 0.3
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchasesSuccessScale = 1.0
                }
            }
            
            await refreshEditData()
            
            // 1초 후 알럿 자동 닫기 및 저장 후 화면 이동
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
            
            await saveBundleChanges()
            await MainActor.run {
                showPurchaseSuccessAlert = false
                purchasesSuccessScale = 0.3
            }
            
        } else {
            // 구매 실패
            await MainActor.run {
                isPurchasing = false
                // 시트 먼저 닫기
                showPurchaseSheet = false
            }
            
            // 시트 닫히는 애니메이션 대기
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                showPurchaseFailAlert = true
                purchaseFailScale = 0.3
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseFailScale = 1.0
                }
            }
        }
    }
}

// MARK: - 키링 데이터 로딩
extension BundleEditView {
    /// 키링 데이터를 로드하여 MultiKeyringScene에서 사용할 수 있도록 준비
    private func loadKeyringData() async {
        guard let bundle = viewModel.selectedBundle,
              let carabiner = newSelectedCarabiner?.carabiner else {
            await MainActor.run {
                keyringDataList = []
            }
            return
        }
        
        // 기존 방식으로도 로드 (Firebase에서 직접)
        let firebaseData = await viewModel.createKeyringDataList(bundle: bundle, carabiner: carabiner)
        
        await MainActor.run {
            // selectedKeyrings 방식으로도 업데이트
            updateKeyringDataList()
            
            // 두 방식 중 더 많은 데이터를 가진 것 사용
            if firebaseData.count > keyringDataList.count {
                keyringDataList = firebaseData
            }
        }
    }
}

