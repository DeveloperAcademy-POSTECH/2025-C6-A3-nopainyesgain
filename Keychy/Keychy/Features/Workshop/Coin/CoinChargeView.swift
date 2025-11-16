//
//  CoinChargeView.swift
//  Keychy
//
//  Created by rundo on 10/27/25.
//

import SwiftUI
import StoreKit

struct CoinChargeView<Route: Hashable>: View {
    @Bindable var router: NavigationRouter<Route>
    @State private var manager = PurchaseManager.shared
    @State private var userManager = UserManager.shared
    
    // 구매 시트 프로필
    @State var showPurchaseSheet = false
    @State var purchaseSheetHeight: CGFloat = 400
    @State var selectedItem: OtherItem?
    
    // 성공/실패 Alert
    @State var showPurchaseSuccessAlert = false
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 37) {
                    
                    // 내 아이템들 현황판
                    CurrentItemsCard()
                    
                    // 코인 구매 섹션
                    coinSection
                    
                    // 기타 아이템 섹션
                    otherItemsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 25)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.never)
            .navigationTitle("충전하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(showPurchaseSuccessAlert || showPurchaseFailAlert)
            .animation(.easeInOut(duration: 0.2), value: showPurchaseSuccessAlert)
            .animation(.easeInOut(duration: 0.2), value: showPurchaseFailAlert)
            .sheet(isPresented: $showPurchaseSheet) {
                purchaseSheet
            }
            .allowsHitTesting(!showPurchaseSuccessAlert && !showPurchaseFailAlert)

            // 구매 성공 Alert - KeychyAlert 사용
            KeychyAlert(
                type: .checkmark,
                message: "구매가 완료되었어요!",
                isPresented: $showPurchaseSuccessAlert
            )

            // 구매 실패 Alert - PurchaseFailAlert 사용
            if showPurchaseFailAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {}

                    PurchaseFailAlert(
                        checkmarkScale: purchaseFailScale,
                        onCancel: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                purchaseFailScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showPurchaseFailAlert = false
                            }
                        },
                        onCharge: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                purchaseFailScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showPurchaseFailAlert = false
                            }
                        }
                    )
                    .padding(.horizontal, 40)
                }
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        purchaseFailScale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Coin Section 코인 구매 섹션
extension CoinChargeView {
    private var coinSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("코인")
            
            VStack(spacing: 30) {
                ForEach(manager.products, id: \.id) { product in
                    coinRow(for: product)
                }
            }
        }
    }
    
    private func coinRow(for product: Product) -> some View {
        HStack(spacing: 8) {
            Image(.buyKey)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            if let storeProduct = StoreProduct(rawValue: product.id) {
                Text("\(storeProduct.coinAmount)개")
                    .typography(.nanum18EB)
                    .foregroundStyle(.main500)
            }
            
            Spacer()
            
            Button {
                Task {
                    do {
                        try await manager.purchase(product)
                    } catch {
                        print("구매 실패: \(error.localizedDescription)")
                    }
                }
            } label: {
                Text(product.displayPrice)
                    .typography(.suit14M)
                    .foregroundStyle(.white100)
                    .frame(width: 74, height: 30)
                    .background(.black100)
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Other Items Section 하단 기타 아이템 섹션
extension CoinChargeView {
    private var otherItemsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("기타 아이템")
            
            VStack(spacing: 30) {
                otherItemRow(item: .inventoryExpansion)
                otherItemRow(item: .copyVoucher10)
            }
        }
    }
    
    private func otherItemRow(item: OtherItem) -> some View {
        HStack(spacing: 10) {
            Image(item.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .typography(.suit16M)
                    .foregroundStyle(.black100)
                
                Text(item.itemDescription)
                    .typography(.suit13M)
                    .foregroundStyle(.gray500)
            }
            
            Spacer()
            
            Button {
                selectedItem = item
                showPurchaseSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(.buyKey)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    Text("\(item.price)")
                        .typography(.suit14SB18)
                        .foregroundStyle(.white)
                }
                .frame(width: 74, height: 30)
                .background(.black100)
                .cornerRadius(4)
            }
        }
    }
}

// MARK: - purchaseSheet 구매 시트
extension CoinChargeView {
    var purchaseSheet: some View {
        VStack(spacing: 0) {
            /// 상단 닫기, 타이틀
            ZStack {
                Text("구매하기")
                    .typography(.suit15B25)
                    .foregroundStyle(.black100)
                
                HStack {
                    dismissButton
                        .padding(.leading, 20)
                    Spacer()
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 22)
            
            /// 구매 아이템 표시
            if let item = selectedItem {
                purchaseItemRow(item: item)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            
            Spacer()
            
            // 내 보유 포인트
            HStack(spacing: 4) {
                Text("내 보유 :")
                    .typography(.suit15M25)
                    .foregroundStyle(.black100)
                
                Text("\(UserManager.shared.currentUser?.coin ?? 0)")
                    .typography(.nanum16EB)
                    .foregroundStyle(.main500)
            }
            .padding(.bottom, 16)
            
            // 구매 버튼
            purchaseButton
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: PurchaseSheetHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        )
        .background(Color.white100)
        .presentationBackground(Color.white100)
        .onPreferenceChange(PurchaseSheetHeightPreferenceKey.self) { height in
            if height > 0 {
                purchaseSheetHeight = height
            }
        }
        .presentationDetents([.height(purchaseSheetHeight)])
    }
    
    private var dismissButton: some View {
        Button {
            showPurchaseSheet = false
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 20))
                .foregroundStyle(.black100)
        }
    }
    
    private func purchaseItemRow(item: OtherItem) -> some View {
        HStack(spacing: 0) {
            Image(item.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(.trailing, 12)
            
            Text(item.title)
                .typography(.suit17B)
                .foregroundStyle(.black100)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image("myCoin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("\(item.price)")
                    .typography(.nanum16EB)
                    .foregroundStyle(.main500)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray50)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var purchaseButton: some View {
        Button {
            Task {
                await handlePurchase()
            }
        } label: {
            HStack(spacing: 5) {
                Image("purchaseSheet")
                
                Text("\(selectedItem?.price ?? 0)")
                    .typography(.nanum18EB12)
                
                Text("(1개)")
                    .typography(.suit17SB)
            }
            .foregroundStyle(.white100)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.black80)
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
    }
}

// MARK: - Other Item 기타 아이템 모델
extension CoinChargeView {
    enum OtherItem {
        case inventoryExpansion
        case copyVoucher10
        
        var icon: String {
            switch self {
            case .inventoryExpansion: return "invenIcon"
            case .copyVoucher10: return "copyBlack"
            }
        }
        
        var title: String {
            switch self {
            case .inventoryExpansion: return "보관함 10칸 확장"
            case .copyVoucher10: return "키링 복사권 10개"
            }
        }
        
        var itemDescription: String {
            switch self {
            case .inventoryExpansion:
                return "키링을 더 많이 만들 수 있어요!"
            case .copyVoucher10:
                return "키링을 더 자유롭게 추가할 수 있어요!"
            }
        }
        
        var price: Int {
            switch self {
            case .inventoryExpansion: return 5
            case .copyVoucher10: return 20
            }
        }
    }
}

// MARK: - 재사용 Components
extension CoinChargeView {
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .typography(.suit15M25)
            .foregroundStyle(.gray500)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - PreferenceKey
struct PurchaseSheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 301
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

