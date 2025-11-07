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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                currentItemsSection
                coinSection
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
    }
}

// MARK: - Current Items Section
extension CoinChargeView {
    private var currentItemsSection: some View {
        HStack(spacing: 20) {
            currentItemCard(
                image: "myCoin",
                title: "열쇠",
                count: "\(userManager.currentUser?.coin ?? 0)"
            )
            
            currentItemCard(
                image: "myKeyringCount",
                title: "내 보유 키링",
                count: "\(userManager.currentUser?.keyrings.count ?? 0)/\(userManager.currentUser?.maxKeyringCount ?? 100)"
            )
            
            currentItemCard(
                image: "myCopyPass",
                title: "복사권",
                count: "\(userManager.currentUser?.copyVoucher ?? 0)/10"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 5)
        .padding(.bottom, 15)
        .background(.gray50)
        .cornerRadius(15)
    }
    
    private func currentItemCard(image: String, title: String, count: String) -> some View {
        VStack(spacing: 5) {
            Image(image)
                .padding(.vertical, 8)
                .padding(.horizontal, 35)
            
            Text(title)
                .typography(.suit12M)
                .foregroundStyle(.black100)
            
            Text(count)
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
        }
    }
}

// MARK: - Coin Section
extension CoinChargeView {
    private var coinSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("코인")
            
            VStack(spacing: 15) {
                ForEach(manager.products, id: \.id) { product in
                    coinRow(for: product)
                }
            }
        
            Divider()
                .padding(.top, 20)
        }
    }
    
    private func coinRow(for product: Product) -> some View {
        HStack(spacing: 8) {
            Image("myCoin")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            if let storeProduct = StoreProduct(rawValue: product.id) {
                Text("\(storeProduct.coinAmount)개")
                    .typography(.suit17M)
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
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.black)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Other Items Section
extension CoinChargeView {
    private var otherItemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("기타 아이템")
            
            VStack(spacing: 15) {
                otherItemRow(
                    icon: "myKeyringCount",
                    title: "인벤토리 확장권",
                    subtitle: "내 보유 10",
                    cost: 1200
                )
                
                otherItemRow(
                    icon: "myCopyPass",
                    title: "내 키링 복사권 10개",
                    subtitle: "내 보유 0",
                    cost: 1200
                )
            }
        }
    }
    
    private func otherItemRow(icon: String, title: String, subtitle: String, cost: Int) -> some View {
        HStack(spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .typography(.suit17M)
                    .foregroundStyle(.black100)
                
                Text(subtitle)
                    .typography(.suit12M25)
                    .foregroundStyle(.main500)
            }
            
            Spacer()
            
            Button {
                // TODO: 아이템 구매 로직
            } label: {
                HStack(spacing: 4) {
                    Image("myCoin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    
                    Text("\(cost)")
                        .typography(.suit14M)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Reusable Components
extension CoinChargeView {
    /// 섹션 타이틀 텍스트
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .typography(.suit15M25)
            .foregroundStyle(.gray500)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CoinChargeView(router: NavigationRouter<HomeRoute>())
    }
}
