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
    @State var collectionVM: CollectionViewModel
    @State var bundleVM: BundleViewModel
    
    @State var isSceneReady = false
    
    @State var selectedCategory: String = ""
    // 선택한 카라비너는 확인 알럿 후에만 바뀜
    @State var selectCarabiner: CarabinerViewData?
    
    // 배경, 카라비너 선택 시트 활성화/비활성화
    @State var showBackgroundSheet: Bool = false
    @State var showCarabinerSheet: Bool = false
    // 카라비너 변경 확인 알러트 ('카라비너 변경 시 키링은 모두 초기화됩니다')
    @State var showChangeCarabinerAlert: Bool = false
    // 시트 높이 (화면의 약 43%에 해당)
    @State var sheetHeight: CGFloat = 360
    
    // 구매 시트
    @State var showPurchaseSheet = false
    
    // 구매 처리 상태
    @State var isPurchasing = false
    
    // 구매 Alert 애니메이션
    @State var showPurchaseSuccessAlert = false
    @State var purchasesSuccessScale: CGFloat = 0.3
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3
    
    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    @State var keyringDataList: [MultiKeyringScene.KeyringData] = []
    
    // 키링 편집 관련 상태
    @State var showSelectKeyringSheet = false
    @State var selectedPosition = 0
    @State var sceneRefreshId = UUID()
    @State var isNavigatingAway = false // 화면 전환 중인지 추적
    
    // 캡쳐 상태
    @State var isCapturing: Bool = false
    
    // 키링 시트 로딩 상태
    @State var isKeyringSheetLoading: Bool = true
    
    // 공통 그리드 컬럼 (배경, 카라비너, 키링 모두 동일)
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    let sheetHeightRatio: CGFloat = 0.43
    
    var body: some View {
        ZStack(alignment: .bottom) {
            mainContentView
                .blur(radius: showPurchaseSuccessAlert ? 15 : 0)
            
            loadingOverlay
            
            // 키링 선택 시트
            keyringSheetOverlay
                .blur(radius: showPurchaseSuccessAlert ? 15 : 0)
            
            // 배경, 카라비너 선택 시트
            selectItemSheetContent
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
                await bundleVM.refreshEditData()
            }
            collectionVM.hideTabBar()
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
        .onChange(of: bundleVM.newSelectedBackground) { _, newBackground in
            guard newBackground != nil else { return }
            // 배경 변경 시에는 키링 데이터 업데이트만 수행 (Firebase 접근 없음)
            updateKeyringDataList()
        }
        .onChange(of: bundleVM.newSelectedCarabiner) { _, newCarabiner in
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
            if let bundle = bundleVM.selectedBundle,
               let background = bundleVM.newSelectedBackground,
               let carabiner = bundleVM.newSelectedCarabiner {
                
                keyringEditSceneView(bundle: bundle, background: background, carabiner: carabiner)
                
            } else {
                placeholderImageView
            }
        }
    }
    
    /// Placeholder 이미지 뷰 (데이터 로드 전)
    private var placeholderImageView: some View {
        ZStack {
            if let bg = bundleVM.newSelectedBackground {
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
            if let cb = bundleVM.newSelectedCarabiner {
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
    
    // MARK: - 데이터 로딩 및 초기화
    
    /// 초기 데이터 로딩
    private func initializeData() async {
        
        // 데이터를 새로 로드하므로 씬도 새로 로드됨
        await MainActor.run {
            isSceneReady = false
            isKeyringSheetLoading = true
        }
        
        // 사용자 키링 데이터 로드
        let uid = UserManager.shared.userUID
        await withCheckedContinuation { continuation in
            collectionVM.fetchUserKeyrings(uid: uid) { success in
                bundleVM.keyring = collectionVM.keyring
                continuation.resume()
            }
        }
        
        // 배경/카라비너 데이터 로드
        await withCheckedContinuation { continuation in
            bundleVM.fetchAllBackgrounds { _ in
                if let selectedBundle = bundleVM.selectedBundle {
                    if bundleVM.newSelectedBackground == nil {
                        bundleVM.newSelectedBackground = bundleVM.backgroundViewData.first { bgData in
                            bgData.background.id == selectedBundle.selectedBackground
                        }
                    }
                }
                self.restoreBackgroundSelection()
                
                bundleVM.fetchAllCarabiners { _ in
                    if let selectedBundle = bundleVM.selectedBundle {
                        if bundleVM.newSelectedCarabiner == nil {
                            bundleVM.newSelectedCarabiner = bundleVM.carabinerViewData.first { cbData in
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
                        
                        isKeyringSheetLoading = false
                        
                        // 씬 재구성 조건 설정
                        if !keyringDataList.isEmpty {
                            sceneRefreshId = UUID()
                        }
                    }
                    // 키링 데이터까지 불러오고 난 후에도 키링의 개수가 0개라면 바로 씬을 준비 완료 상태로 체크
                    if keyringDataList.isEmpty {
                        isSceneReady = true
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    /// Firebase 데이터를 로컬 상태로 한 번만 초기화
    private func initializeSelectedKeyringsFromFirebase() async {
        guard let bundle = bundleVM.selectedBundle else {
            return
        }
        
        let result = await bundleVM.convertBundleToSelectedKeyrings(bundle: bundle)
        bundleVM.selectedKeyrings = result.0
        bundleVM.keyringOrder = result.1
    }
    
    /// 키링 데이터 리스트 업데이트
    func updateKeyringDataList() {
        guard let carabiner = bundleVM.newSelectedCarabiner?.carabiner else {
            keyringDataList = []
            return
        }
        
        let newData = bundleVM.createKeyringDataListFromSelected(
            selectedKeyrings: bundleVM.selectedKeyrings,
            keyringOrder: bundleVM.keyringOrder,
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
    
    // MARK: - 선택 상태 저장/복원
    func saveCurrentSelection() {
        if let bg = bundleVM.newSelectedBackground {
            UserDefaults.standard.set(bg.background.id, forKey: "tempSelectedBackgroundId")
        }
        if let cb = bundleVM.newSelectedCarabiner {
            UserDefaults.standard.set(cb.carabiner.id, forKey: "tempSelectedCarabinerId")
        }
    }
    
    func restoreSelection() {
        restoreBackgroundSelection()
        restoreCarabinerSelection()
    }
    
    func restoreBackgroundSelection() {
        if let savedBackgroundId = UserDefaults.standard.string(forKey: "tempSelectedBackgroundId") {
            if let restoredBackground = bundleVM.backgroundViewData.first(where: { $0.background.id == savedBackgroundId }) {
                bundleVM.newSelectedBackground = restoredBackground
                // 복원 후 삭제
                UserDefaults.standard.removeObject(forKey: "tempSelectedBackgroundId")
            }
        }
    }
    
    func restoreCarabinerSelection() {
        if let savedCarbinerId = UserDefaults.standard.string(forKey: "tempSelectedCarabinerId") {
            if let restoredCarabiner = bundleVM.carabinerViewData.first(where: { $0.carabiner.id == savedCarbinerId }) {
                bundleVM.newSelectedCarabiner = restoredCarabiner
                // 복원 후 삭제
                UserDefaults.standard.removeObject(forKey: "tempSelectedCarabinerId")
            }
        }
    }
    
    // MARK: - 썸네일 재캡쳐 & 캐시 저장
    private func recaptureAndCacheBundleThumbnail(bundleId: String, bundleName: String) async {
        // 편집 중 상태로 캡쳐
        guard let bg = bundleVM.newSelectedBackground?.background,
              let cb = bundleVM.newSelectedCarabiner?.carabiner else {
            return
        }
        
        await MainActor.run {
            isCapturing = true
        }
        
        // 캡쳐용 키링 데이터 생성 (편집 중 keyringDataList -> 캡쳐용으로 변환)
        let captureKeyrings: [MultiKeyringCaptureScene.KeyringData] = keyringDataList.map { item in
            MultiKeyringCaptureScene.KeyringData(
                index: item.index,
                position: item.position,
                bodyImageURL: item.bodyImageURL,
                hookOffsetY: item.hookOffsetY,
                chainLength: item.chainLength
            )
        }
        
        // 카라비너 타입 및 이미지 URL
        let carabinerType = cb.type
        let carabinerBackURL: String?
        let carabinerFrontURL: String?
        if carabinerType == .hamburger {
            carabinerBackURL = cb.carabinerImage[1]
            carabinerFrontURL = cb.carabinerImage[2]
        } else {
            carabinerBackURL = cb.carabinerImage[0]
            carabinerFrontURL = nil
        }
        
        // 캡쳐
        if let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: captureKeyrings,
            backgroundImageURL: bg.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerX: cb.carabinerX,
            carabinerY: cb.carabinerY,
            carabinerWidth: cb.carabinerWidth
        ) {
            // 캐시 저장
            BundleImageCache.shared.syncBundle(
                id: bundleId,
                name: bundleName,
                imageData: pngData
            )
            await MainActor.run {
                bundleVM.bundleCapturedImage = pngData
                isCapturing = false
            }
        } else {
            await MainActor.run {
                isCapturing = false
            }
        }
    }
}

// MARK: - 툴바
extension BundleEditView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                isNavigatingAway = true
                router.pop()
            }
        } center: {
        } trailing: {
            let hasPayableItems = (bundleVM.newSelectedBackground != nil && !bundleVM.newSelectedBackground!.isOwned && bundleVM.newSelectedBackground!.background.price > 0) || (bundleVM.newSelectedCarabiner != nil && !bundleVM.newSelectedCarabiner!.isOwned && bundleVM.newSelectedCarabiner!.carabiner.price > 0)
            
            if hasPayableItems {
                let payableCount = ((bundleVM.newSelectedBackground != nil && !bundleVM.newSelectedBackground!.isOwned && bundleVM.newSelectedBackground!.background.price > 0) ? 1 : 0) + ((bundleVM.newSelectedCarabiner != nil && !bundleVM.newSelectedCarabiner!.isOwned && bundleVM.newSelectedCarabiner!.carabiner.price > 0) ? 1 : 0)
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
                            let bgId = bundleVM.makeBackgroundId(bundleVM.newSelectedBackground?.background ?? bundleVM.resolveBackground(from: bundleVM.selectedBundle?.selectedBackground ?? ""))
                            let cbId = bundleVM.makeCarabinerId(bundleVM.newSelectedCarabiner?.carabiner ?? bundleVM.resolveCarabiner(from: bundleVM.selectedBundle?.selectedCarabiner ?? ""))
                            
                            // 편집 중 키링 데이터 기준으로 keyringsId 생성
                            let currentKeyringDataList = keyringDataList
                            let krId = bundleVM.makeKeyringsId(currentKeyringDataList)
                            
                            bundleVM.returnBackgroundId = bgId
                            bundleVM.returnCarabinerId = cbId
                            bundleVM.returnKeyringsId = krId
                            
                            // 화면 전환 시작 플래그
                            isNavigatingAway = true
                        }
                        
                        // 상태 변경이 UI에 반영되도록 짧은 대기
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
                        await bundleVM.saveBundleChanges()
                        
                        // 저장 후 썸네일 재캡쳐, 캐시 저장
                        if let bundle = bundleVM.selectedBundle, let documentId = bundleVM.selectedBundle?.documentId {
                            await recaptureAndCacheBundleThumbnail(bundleId: documentId, bundleName: bundle.name)
                        }
                        
                        await MainActor.run {
                            router.pop()
                        }
                    }
                }
            }
        }
    }
}
