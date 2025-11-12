//
//  BundleEditView.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI
import NukeUI

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
    @State private var sheetHeight: CGFloat = 360
    // 장바구니에 담긴 아이템들 (유료 아이템만)
    @State private var cartItems: [CartItem] = []
    
    // 구매 시트
    @State var showPurchaseSheet = false
    
    // 구매 처리 상태
    @State private var isPurchasing = false
    
    // 구매 Alert 애니메이션
    @State var showPurchaseSuccessAlert = false
    @State var purchasesSuccessScale: CGFloat = 0.3
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                //TODO: 임시로 올려둔 배경화면과 카라비너입니다.
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
                // 배경 시트
                if showBackgroundSheet {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            editBackgroundButton
                            editCarabinerButton
                            Spacer()
                        }
                        .padding(.leading, 18)
                        BundleItemCustomSheet(
                            sheetHeight: $sheetHeight,
                            content: selectBackgroundSheet(geo: geo)
                        )
                    }
                }
                
                // 카라비너 시트
                if showCarabinerSheet {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            editBackgroundButton
                            editCarabinerButton
                            Spacer()
                        }
                        .padding(.leading, 18)
                        BundleItemCustomSheet(
                            sheetHeight: $sheetHeight,
                            content: selectCarabinerSheet(geo: geo)
                        )
                    }
                }
                
                if !showCarabinerSheet && !showBackgroundSheet {
                    HStack(spacing: 8) {
                        editBackgroundButton
                        editCarabinerButton
                        Spacer()
                    }
                    .padding(.leading, 18)
                }
                
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
                                newSelectedCarabiner = selectCarabiner
                                showChangeCarabinerAlert = false
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
                            showPurchaseSuccessAlert = false
                            purchasesSuccessScale = 0.3
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
        .toolbar {
            backButton
            editCompleteButton
        }
        .sheet(isPresented: $showPurchaseSheet) {
            purchaseSheetView
        }
        .navigationBarBackButtonHidden()
        .task {
            viewModel.fetchAllBackgrounds { _ in
                if let selectedBundle = viewModel.selectedBundle {
                    // selectedBackground는 ID(String)이므로 BackgroundViewData를 찾아야 함
                    if newSelectedBackground == nil {
                        newSelectedBackground = viewModel.backgroundViewData.first { bgData in
                            bgData.background.id == selectedBundle.selectedBackground
                        }
                    }
                }
                viewModel.fetchAllCarabiners { _ in
                    if let selectedBundle = viewModel.selectedBundle {
                        // selectedCarabiner도 동일하게 ID로 CarabinerViewData를 찾음
                        if newSelectedCarabiner == nil {
                            newSelectedCarabiner = viewModel.carabinerViewData.first { cbData in
                                cbData.carabiner.id == selectedBundle.selectedCarabiner
                            }
                        }
                    }
                }
            }
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
                if cartItems.isEmpty {
                    // 그냥 다음 화면으로 이동
                } else {
                    showPurchaseSheet = true
                }
            } label: {
                if cartItems.isEmpty {
                    Text("다음")
                        .typography(.suit17B)
                        .foregroundStyle(.black100)
                        .padding(.vertical, 7.5)
                        .padding(.horizontal, 6)
                } else {
                    Text("구매 \(cartItems.count)")
                }
            }
            .buttonStyle(.glassProminent)
            .tint(cartItems.isEmpty ? .white : .black80)
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
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.backgroundViewData) { bg in
                SelectBackgroundGridItem(
                    background: bg,
                    isSelected: newSelectedBackground == bg,
                    widthSize: geo.size.width
                )
                .onTapGesture {
                    newSelectedBackground = bg
                    
                    // 무료이고, 유저가 보유x
                    if !bg.isOwned && bg.background.isFree {
                        Task {
                            await viewModel.addBackgroundToUser(backgroundName: bg.background.backgroundName, userManager: UserManager.shared)
                        }
                    }
                    
                    // 유료이고, 유저가 보유x
                    if !bg.isOwned && bg.background.price > 0 {
                        let cartItem = CartItem.background(bg)
                        if !cartItems.contains(cartItem) {
                            cartItems.append(cartItem)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
    
    private func selectCarabinerSheet(geo: GeometryProxy) -> some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.carabinerViewData) { cb in
                SelectCarabinerGridItem(isSelected: newSelectedCarabiner == cb, carabiner: cb, widthSize: geo.size.width)
                    .onTapGesture {
                        selectCarabiner = cb
                        showChangeCarabinerAlert = true
                        
                        // 무료 카라비너는 바로 유저 carabiner 배열에 추가
                        if !cb.isOwned && cb.carabiner.isFree {
                            Task {
                                await viewModel.addCarabinerToUser(carabinerName: cb.carabiner.carabinerName, userManager: UserManager.shared)
                            }
                        }
                        
                        if !cb.isOwned && cb.carabiner.price > 0 {
                            let cartItem = CartItem.carabiner(cb)
                            if !cartItems.contains(cartItem) {
                                cartItems.append(cartItem)
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
                    ForEach(cartItems) { item in
                        cartItemRow(item: item)
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
    
    private func cartItemRow(item: CartItem) -> some View {
        HStack(spacing: 6) {
            Image(.selected)
                .resizable()
                .scaledToFit()
                .frame(width: 22.5, height: 22.5)
            
            Text(item.name)
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.trailing, 7)
            
            switch item {
            case .background:
                Text("배경")
                    .typography(.suit13M)
                    .foregroundStyle(.gray400)
            case .carabiner:
                Text("카라비너")
                    .typography(.suit13M)
                    .foregroundStyle(.gray400)
            }
            
            Spacer()
            
            Text("\(item.price)")
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
                
                Text("(\(cartItems.count)개)")
                    .typography(.suit17SB)
            }
            .foregroundStyle(.white100)
            .frame(maxWidth: .infinity)
            .background(isPurchasing ? .gray400 : .black80)
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
        .disabled(isPurchasing)
    }
    
    var totalCartPrice: Int {
        cartItems.reduce(0) { $0 + $1.price}
    }
    
    // MARK: - 구매 처리
    private func purchaseItems() async {
        isPurchasing = true
        
        var allSuccess = true
        var hasInsufficientCoins = false
        
        for cartItem in cartItems {
            let result: PurchaseResult
            
            switch cartItem {
            case .background(let bgData):
                result = await ItemPurchaseManager.shared.purchaseWorkshopItem(bgData.background, userManager: UserManager.shared)
            case .carabiner(let cbData):
                result = await ItemPurchaseManager.shared.purchaseWorkshopItem(cbData.carabiner, userManager: UserManager.shared)
            }
            
            switch result {
            case .success:
                continue
            case .insufficientCoins:
                hasInsufficientCoins = true
                allSuccess = false
                break
            case .failed(_):
                allSuccess = false
                break
            }
        }
        
        if allSuccess {
            // 모든 구매 성공
            await MainActor.run {
                isPurchasing = false
                cartItems.removeAll()
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
