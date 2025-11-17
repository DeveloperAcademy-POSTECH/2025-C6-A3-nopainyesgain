//
//  BundleCreateView.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI
import NukeUI
import SceneKit
import FirebaseFirestore

struct BundleCreateView: View {
    
    //MARK: - 프로퍼티들
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    /// 선택한 카테고리 : "Background" 또는 "Carabiner"
    @State private var selectedCategory: String = ""
    
    // 선택한 배경과 카라비너
    @State private var selectedBackground: BackgroundViewData?
    @State private var selectedCarabiner: CarabinerViewData?
    
    // 시트 활성화 상태
    @State private var showBackgroundSheet: Bool = false
    @State private var showCarabinerSheet: Bool = false
    
    // 임시 초기값
    @State private var sheetHeight: CGFloat = 360
    private let sheetHeightRatio: CGFloat = 0.5
    
    // 구매 시트
    @State var showPurchaseSheet = false
    
    // 구매 처리 상태
    @State private var isPurchasing = false
    
    // 구매 Alert 애니메이션
    @State var showPurchaseSuccessAlert = false
    @State var purchasesSuccessScale: CGFloat = 0.3
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3
    
    
    // 공통 그리드 컬럼 (배경, 카라비너, 키링 모두 동일)
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    //MARK: 메인 뷰
    var body: some View {
        ZStack(alignment: .bottom) {
            if let background = selectedBackground,
               let carabiner = selectedCarabiner {
                selectedView(
                    bg: background,
                    cb: carabiner
                )
                
                sheetContent()
            } else {
                // 로딩 중일 때
                // 기본 배경 이미지와 로딩 중 애니메이션..
                Image(.greenBackground)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    Image(.introTypo)
                        .resizable()
                        .scaledToFit()
                    Text("로딩 중이에요")
                    Spacer()
                }
            }
            
            // Alert들
            alertContent
            
            customNavigationBar
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showPurchaseSheet) {
            purchaseSheetView
        }
        .task {
            await initializeData()
        }
        .onAppear {
            // 화면이 나타날 때마다 데이터 새로고침
            Task {
                await refreshData()
            }
            
            // 화면 첫 진입 시 배경 시트를 보여줌
            if !showBackgroundSheet && !showCarabinerSheet {
                showBackgroundSheet = true
            }
        }
        // 선택 타입이 배경화면이면 카라비너 시트는 닫고, 카라비너 열리면 배경화면은 닫힘
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
        // 선택한 배경과 카라비너를 ViewModel과 자동 동기화
        .onChange(of: selectedBackground) { _, newValue in
            if let bg = newValue {
                viewModel.selectedBackground = bg.background
            }
        }
        .onChange(of: selectedCarabiner) { _, newValue in
            if let cb = newValue {
                viewModel.selectedCarabiner = cb.carabiner
            }
        }
    }
}

// MARK: - 커스텀 네비게이션 바
extension BundleCreateView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        } center: {
            Text("배경 및 카라비너 선택")
                .typography(.notosans17M)
                .foregroundStyle(.black100)
        } trailing: {
            if hasUnpurchasedItems {
                PurchaseToolbarButton(title: "구매 \(payableItemsCount)") {
                    showPurchaseSheet = true
                }
            } else {
                NextToolbarButton {
                    router.push(.bundleAddKeyringView)
                }
                .buttonStyle(.glass)
            }
        }
        
    }
}

//MARK: - 시트 뷰
extension BundleCreateView {
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
                            selectedBG: selectedBackground,
                            onBackgroundTap: { bg in
                                selectedBackground = bg
                            }
                        ),
                        screenHeight: screenHeight
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
                            selectedCarabiner: selectedCarabiner,
                            onCarabinerTap: { carabiner in
                                selectedCarabiner = carabiner
                            }
                        ),
                        screenHeight: screenHeight
                    )
                }
            }
        }
    }
}

// MARK: - 배경, 카라비너 뷰
extension BundleCreateView {
    private func selectedView(bg: BackgroundViewData, cb: CarabinerViewData) -> some View {
        // 배경과 카라비너만 보여줌
        MultiKeyringSceneView(
            keyringDataList: [],
            ringType: .basic,
            chainType: .basic,
            backgroundColor: .clear,
            backgroundImageURL: bg.background.backgroundImage,
            carabinerBackImageURL: cb.carabiner.backImageURL,
            carabinerFrontImageURL: cb.carabiner.frontImageURL,
            carabinerX: cb.carabiner.carabinerX,
            carabinerY: cb.carabiner.carabinerY,
            carabinerWidth: cb.carabiner.carabinerWidth,
            currentCarabinerType: cb.carabiner.type
        )
        .ignoresSafeArea()
        .id("scene_\(bg.background.id ?? "bg")_\(cb.carabiner.id ?? "cb")")
    }
}



// MARK: - 데이터 가져오는 메서드
extension BundleCreateView {
    
    /// 초기 데이터 로딩
    private func initializeData() async {
        // 사용자가 소유한 배경과 카라비너 데이터를 가져옴
        await loadUserOwnedItems()
    }
    
    /// 화면이 다시 나타날 때 데이터 새로고침
    private func refreshData() async {
        guard let _ = UserManager.shared.currentUser else {
            return
        }
        
        // 현재 선택된 아이템의 ID 저장
        let currentBackgroundId = selectedBackground?.background.id
        let currentCarabinerId = selectedCarabiner?.carabiner.id
        
        // 배경 데이터 새로고침
        await withCheckedContinuation { continuation in
            viewModel.fetchAllBackgrounds { _ in
                // 이전에 선택했던 배경을 다시 찾아서 선택 (구매 상태가 업데이트됨)
                if let bgId = currentBackgroundId {
                    self.selectedBackground = viewModel.backgroundViewData.first { $0.background.id == bgId }
                }
                continuation.resume()
            }
        }
        
        // 카라비너 데이터 새로고침
        await withCheckedContinuation { continuation in
            viewModel.fetchAllCarabiners { _ in
                // 이전에 선택했던 카라비너를 다시 찾아서 선택 (구매 상태가 업데이트됨)
                if let cbId = currentCarabinerId {
                    self.selectedCarabiner = viewModel.carabinerViewData.first { $0.carabiner.id == cbId }
                }
                continuation.resume()
            }
        }
    }
    
    /// 사용자가 소유한 배경과 카라비너 아이템들을 로드
    private func loadUserOwnedItems() async {
        guard let _ = UserManager.shared.currentUser else {
            return
        }
        
        // 배경 데이터 로드
        await withCheckedContinuation { continuation in
            viewModel.fetchAllBackgrounds { _ in
                // 가장 첫 번째 배경을 기본으로 선택
                if self.selectedBackground == nil {
                    self.selectedBackground = viewModel.backgroundViewData.first
                }
                
                continuation.resume()
            }
        }
        
        // 카라비너 데이터 로드
        await withCheckedContinuation { continuation in
            viewModel.fetchAllCarabiners { _ in
                // 가장 첫 번째 카라비너를 기본으로 선택
                if self.selectedCarabiner == nil {
                    self.selectedCarabiner = viewModel.carabinerViewData.first
                }
                
                continuation.resume()
            }
        }
    }
}

// MARK: - Alert 컨텐츠
extension BundleCreateView {
    private var alertContent: some View {
        Group {
            // 구매 성공 Alert
            if showPurchaseSuccessAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        showPurchaseSuccessAlert = false
                        purchasesSuccessScale = 0.3
                        // TODO: 번들 생성 완료 후 화면 이동
                        router.pop()
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
                            router.push(.coinCharge)
                        }
                    )
                    Spacer()
                }
            }
        }
    }
}

// MARK: - 구매 시트 뷰
extension BundleCreateView {
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
                    if let bg = selectedBackground, !bg.isOwned && bg.background.price > 0 {
                        cartItemRow(name: bg.background.backgroundName, type: "배경", price: bg.background.price)
                    }
                    if let cb = selectedCarabiner, !cb.isOwned && cb.carabiner.price > 0 {
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
    
    // 구매 버튼
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
        let backgroundCount = (selectedBackground != nil && !selectedBackground!.isOwned && selectedBackground!.background.price > 0) ? 1 : 0
        let carabinerCount = (selectedCarabiner != nil && !selectedCarabiner!.isOwned && selectedCarabiner!.carabiner.price > 0) ? 1 : 0
        return backgroundCount + carabinerCount
    }
    
    var totalCartPrice: Int {
        let backgroundPrice = (selectedBackground != nil && !selectedBackground!.isOwned && selectedBackground!.background.price > 0) ? selectedBackground!.background.price : 0
        let carabinerPrice = (selectedCarabiner != nil && !selectedCarabiner!.isOwned && selectedCarabiner!.carabiner.price > 0) ? selectedCarabiner!.carabiner.price : 0
        return backgroundPrice + carabinerPrice
    }
    
    // MARK: - 구매 처리
    private func purchaseItems() async {
        isPurchasing = true
        
        var allSuccess = true
        
        // 선택된 배경이 유료인 경우 구매
        if let bg = selectedBackground, !bg.isOwned && bg.background.price > 0 {
            let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(bg.background, userManager: UserManager.shared)
            
            switch result {
            case .success:
                break
            case .insufficientCoins, .failed(_):
                allSuccess = false
            }
        }
        
        // 선택된 카라비너가 유료이고 이전 구매가 성공한 경우에만 구매
        if allSuccess, let cb = selectedCarabiner, !cb.isOwned && cb.carabiner.price > 0 {
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
            
            // 1초 후 알럿 자동 닫기
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
            
            await MainActor.run {
                showPurchaseSuccessAlert = false
                purchasesSuccessScale = 0.3

                router.push(.bundleAddKeyringView)
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

// MARK: - 하단 버튼
extension BundleCreateView {
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
    
    /// 구매하지 않은 유료 아이템이 있는지 확인
    private var hasUnpurchasedItems: Bool {
        let hasUnpurchasedBackground = selectedBackground != nil && !selectedBackground!.isOwned && selectedBackground!.background.price > 0
        let hasUnpurchasedCarabiner = selectedCarabiner != nil && !selectedCarabiner!.isOwned && selectedCarabiner!.carabiner.price > 0
        return hasUnpurchasedBackground || hasUnpurchasedCarabiner
    }
}
