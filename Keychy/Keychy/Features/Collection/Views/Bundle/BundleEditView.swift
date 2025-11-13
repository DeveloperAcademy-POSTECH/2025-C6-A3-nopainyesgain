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

struct BundleEditView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    @State private var selectedCategory: String = ""
    @State private var selectedKeyringPosition: Int = 0
    @State private var newSelectedBackground: BackgroundViewData?
    // 선택한 카라비너 -> 알럿창 확인 눌러야 뉴선택 카라비너로 바뀜
    @State private var selectCarabiner: CarabinerViewData?
    @State private var newSelectedCarabiner: CarabinerViewData?
    
    @State private var showBackgroundSheet: Bool = false
    @State private var showCarabinerSheet: Bool = false
    @State private var showChangeCarabinerAlert: Bool = false
    @State private var sheetHeight: CGFloat = 360 // 시트 높이 (화면의 약 43%에 해당)
    
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
    @State private var isDeleteButtonSelected = false
    @State private var sceneRefreshId = UUID()
    
    // 공통 그리드 컬럼 (배경, 카라비너, 키링 모두 동일)
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    //임시 초기값
    private let sheetHeightRatio: CGFloat = 0.5
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // MultiKeyringScene 또는 키링 편집 뷰
                if let bundle = viewModel.selectedBundle,
                   let background = newSelectedBackground,
                   let carabiner = newSelectedCarabiner {
                    
                    keyringEditSceneView(bundle: bundle, background: background, carabiner: carabiner)
                    
                } else {
                    // 데이터 로딩 중이거나 임시 화면
                    if let bg = newSelectedBackground {
                        LazyImage(url: URL(string: bg.background.backgroundImage)) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .scaledToFit()
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
                
                // 키링 선택 시트
                if showSelectKeyringSheet {
                    keyringSelectionSheet(geo: geo)
                }
                
                // 배경/카라비너 시트들
                sheetContent(geo: geo)
                
                // Alert들
                alertContent
            }
        }
        .toolbar {
            backButton
            editCompleteButton
        }
        .sheet(isPresented: $showPurchaseSheet) {
            purchaseSheetView
        }
        .navigationBarBackButtonHidden()
        .task {
            await initializeData()
        }
        .onAppear {
            showBackgroundSheet = true
        }
        .ignoresSafeArea()
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
                currentCarabinerType: carabiner.carabiner.type
            )
            .ignoresSafeArea()
            .id("scene_\(background.background.id ?? "bg")_\(carabiner.carabiner.id ?? "cb")_\(keyringDataList.count)_\(sceneRefreshId.uuidString)")
            
            // 키링 추가 버튼들
            keyringButtons(carabiner: carabiner.carabiner)
        }
    }
    
    /// 키링 추가 버튼들
    private func keyringButtons(carabiner: Carabiner) -> some View {
        ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
            let position = viewModel.buttonPosition(index: index, carabiner: carabiner)
            
            CarabinerAddKeyringButton(
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
            .position(position)
            .overlay(alignment: .top) {
                if isDeleteButtonSelected && selectedPosition == index && selectedKeyrings[index] != nil {
                    deleteButton()
                        .position(x: position.x, y: position.y)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.spring, value: isDeleteButtonSelected)
                }
            }
        }
    }
    
    /// 키링 선택 시트
    private func keyringSelectionSheet(geo: GeometryProxy) -> some View {
        VStack {
            HStack {
                Spacer()
                Text("키링 선택")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)
                Spacer()
                // 완료 버튼: 닫기만
                Button {
                    withAnimation(.easeInOut) {
                        showSelectKeyringSheet = false
                    }
                } label: {
                    Text("완료")
                        .typography(.suit16M)
                        .foregroundStyle(.gray600)
                }
            }
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
                            keyringCell(keyring: keyring, geo: geo)
                        }
                    }
                }
            }
            
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20))
        .frame(maxWidth: .infinity)
        .frame(height: geo.size.height * sheetHeightRatio)
        .background(.white100)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom))
        .zIndex(2)
    }
    
    /// 키링 셀 (체크 토글 + 시트 유지)
    private func keyringCell(keyring: Keyring, geo: GeometryProxy) -> some View {
        // 현재 선택된 위치에 이 키링이 선택되어 있는지
        let isSelectedHere: Bool = selectedKeyrings[selectedPosition]?.id == keyring.id
        // 다른 위치에 이미 선택된 키링인지 체크
        let isSelectedElsewhere: Bool = selectedKeyrings.values.contains { $0.id == keyring.id } && !isSelectedHere
        let widthSize = (geo.size.width - 60) / 3
        let heightSize = widthSize * 4/3
        
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
            }
            // 중복인 경우 아무것도 하지 않음 (선택되지 않음)
            updateKeyringDataList()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 10) {
                    CollectionCellView(keyring: keyring)
                        .frame(width: widthSize, height: heightSize)
                        .cornerRadius(10)
                    
                    Text("\(keyring.name)")
                        .typography(isSelectedHere ? .notosans14SB : .notosans14M)
                        .foregroundStyle(isSelectedHere ? .main500 :  .black100)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                // 체크 뱃지
                ZStack {
                    Circle()
                        .stroke(.white100)
                        .fill(isSelectedHere ? .main500 : .clear)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 0)
                        .frame(width: 26.14, height: 26.14)
                    Image(.recCheck)
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 35.86)
                .padding(.trailing, 8.86)
                
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
        .buttonStyle(PlainButtonStyle())
        .disabled(keyring.status == .packaged || keyring.status == .published || isSelectedElsewhere)
        .opacity(1.0) // 강제로 투명도 1.0 유지
    }
    
    /// 삭제 버튼
    private func deleteButton() -> some View {
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
            Divider().frame(height: 20)
            Spacer()
            Button {
                selectedKeyrings[selectedPosition] = nil
                keyringOrder.removeAll { $0 == selectedPosition }
                updateKeyringDataList()
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
    
    /// 배경/카라비너 시트 컨텐츠
    private func sheetContent(geo: GeometryProxy) -> some View {
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
                        content: selectBackgroundSheet(geo: geo),
                        screenHeight: geo.size.height
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
                        content: selectCarabinerSheet(geo: geo),
                        screenHeight: geo.size.height
                    )
                }
            }
            
            // 버튼들만 표시 (시트가 없을 때)
            if !showCarabinerSheet && !showBackgroundSheet {
                HStack(spacing: 8) {
                    editBackgroundButton
                    editCarabinerButton
                    Spacer()
                }
                .padding(.leading, 18)
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
                                isDeleteButtonSelected = false
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
                        // Alert 닫을 때 저장 후 화면 이동
                        Task {
                            do {
                                await saveBundleChanges()
                                await MainActor.run {
                                    showPurchaseSuccessAlert = false
                                    purchasesSuccessScale = 0.3
                                    router.pop()
                                }
                            }
                        }
                    }
                
                VStack {
                    Spacer()
                    PurchaseSuccessAlert(checkmarkScale: purchasesSuccessScale)
                    Spacer()
                }
            }
            
            // 구매 실패 Alert
            if showPurchaseFailAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        showPurchaseFailAlert = false
                        purchaseFailScale = 0.3
                    }
                
                VStack {
                    Spacer()
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
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 데이터 로딩 및 초기화
    
    /// 초기 데이터 로딩
    private func initializeData() async {
        
        // 사용자 키링 데이터 로드
        let uid = UserManager.shared.userUID
        await withCheckedContinuation { continuation in
            viewModel.fetchUserKeyrings(uid: uid) { _ in
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
    
    /// 카라비너 변경 시 뭉치의 키링들을 모두 "none"으로 업데이트
    /// - 편집 중에는 Firestore 업데이트를 하지 않으므로 현재 함수는 더 이상 사용하지 않습니다.
    private func updateBundleKeyringsToNone() async {
        // intentionally left unused to avoid mid-edit persistence
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
        
        // selectedKeyrings를 뭉치 형태로 변환
        let keyrings = viewModel.convertSelectedKeyringsToBundleFormat(
            selectedKeyrings: selectedKeyrings,
            maxKeyringCount: carabiner.carabiner.maxKeyringCount
        )
        
        // 키링 데이터 검증
        let validKeyrings = keyrings.map { keyringId in
            return keyringId.isEmpty ? "none" : keyringId
        }
        
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let updateData: [String: Any] = [
                "keyrings": validKeyrings,
                "selectedBackground": backgroundId,
                "selectedCarabiner": carabinerId
            ]
            
            try await db.collection("KeyringBundle").document(documentId).updateData(updateData)
            
            // 로컬 상태도 업데이트
            await MainActor.run {
                if let index = viewModel.bundles.firstIndex(where: { $0.documentId == documentId }) {
                    viewModel.bundles[index].keyrings = validKeyrings
                    viewModel.bundles[index].selectedBackground = backgroundId
                    viewModel.bundles[index].selectedCarabiner = carabinerId
                }
                
                // selectedBundle도 업데이트
                if viewModel.selectedBundle?.documentId == documentId {
                    viewModel.selectedBundle?.keyrings = validKeyrings
                    viewModel.selectedBundle?.selectedBackground = backgroundId
                    viewModel.selectedBundle?.selectedCarabiner = carabinerId
                }
            }
        } catch {
            print("\(error.localizedDescription)")
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

// MARK: - 툴바
extension BundleEditView {
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(.lessThan)
                    .resizable()
                    .scaledToFit()
            }
            .frame(width: 44, height: 44)
            .buttonStyle(.glass)
        }
    }
    private var editCompleteButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                
                let hasPayableItems = (newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) || (newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0)
                
                if hasPayableItems {
                    showPurchaseSheet = true
                } else {
                    // 최종 저장 후 화면 이동
                    Task {
                        do {
                            await saveBundleChanges()
                            await MainActor.run {
                                router.pop()
                            }
                        }
                    }
                }
            } label: {
                let hasPayableItems = (newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) || (newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0)
                
                if hasPayableItems {
                    let payableCount = ((newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) ? 1 : 0) + ((newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0) ? 1 : 0)
                    Text("구매 \(payableCount)")
                } else {
                    Text("다음")
                        .typography(.suit17B)
                        .foregroundStyle(.black100)
                        .padding(.vertical, 7.5)
                        .padding(.horizontal, 6)
                }
            }
            .buttonStyle(.glassProminent)
            .tint(((newSelectedBackground != nil && !newSelectedBackground!.isOwned && newSelectedBackground!.background.price > 0) ||
                   (newSelectedCarabiner != nil && !newSelectedCarabiner!.isOwned && newSelectedCarabiner!.carabiner.price > 0)) ? .black80 : .white)
        }
    }
}

//MARK: - 하단 버튼
extension BundleEditView {
    private var editBackgroundButton: some View {
        Button {
            // 배경 시트 열기
            showBackgroundSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showBackgroundSheet ? .backgroundIconWhite100 : .backgroundIconGray600)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 23.96, height: 25.8)
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
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26.83, height: 23)
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

// MARK: - 시트 뷰
extension BundleEditView {
    private func selectBackgroundSheet(geo: GeometryProxy) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(viewModel.backgroundViewData) { bg in
                SelectBackgroundGridItem(
                    background: bg,
                    isSelected: newSelectedBackground == bg,
                    widthSize: geo.size.width
                )
                .onTapGesture {
                    newSelectedBackground = bg
                    
                    // 무료이고, 유저가 보유x인 경우만 바로 추가
                    if !bg.isOwned && bg.background.isFree {
                        Task {
                            await viewModel.addBackgroundToUser(backgroundName: bg.background.backgroundName, userManager: UserManager.shared)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
    
    private func selectCarabinerSheet(geo: GeometryProxy) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(viewModel.carabinerViewData) { cb in
                SelectCarabinerGridItem(isSelected: newSelectedCarabiner == cb, carabiner: cb, widthSize: geo.size.width)
                    .onTapGesture {
                        selectCarabiner = cb
                        showChangeCarabinerAlert = true
                        
                        // 무료 카라비너인 경우만 바로 추가
                        if !cb.isOwned && cb.carabiner.isFree {
                            Task {
                                await viewModel.addCarabinerToUser(carabinerName: cb.carabiner.carabinerName, userManager: UserManager.shared)
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
}

// MARK: - 구매 시트 뷰
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
        }
        .background(.white100)
        .presentationDetents([.fraction(0.43)])
    }
    
    private func cartItemRow(name: String, type: String, price: Int) -> some View {
        HStack(spacing: 6) {
            Image(.selected)
                .resizable()
                .scaledToFit()
                .frame(width: 22.5, height: 22.5)
            
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
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
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
            
            // 뷰모델 데이터 새로고침
            viewModel.fetchAllBackgrounds { _ in }
            viewModel.fetchAllCarabiners { _ in }
            
            // 저장과 화면 이동은 alert 터치 시 처리
            
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

