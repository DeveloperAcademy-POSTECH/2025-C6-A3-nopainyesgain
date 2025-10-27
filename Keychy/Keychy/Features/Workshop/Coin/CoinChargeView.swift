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
    @Bindable var store = StoreKitManager()
    
    var body: some View {
        List {
            currentCherrySection
            cherrySection
            otherItemsSection
        }
        .navigationTitle("재화 구매")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension CoinChargeView {
    private var currentCherrySection: some View {
        Section {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.red)
                Text("현재 보유한 체리")
                Text("6000")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var cherrySection: some View {
        Section("체리") {
            ForEach(store.products, id: \.id) { product in
                cherryRow(product: product)
            }
        }
    }

    private func cherryRow(product: Product) -> some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundColor(.red)
            Text("\(product.displayName)개")
                .foregroundColor(.red)

            Spacer()
            
            // 구매 버튼
            Button(action: {
                Task {
                    do {
                        _ = try await store.purchase(product)
                    } catch {
                        print("구매 실패: \(error.localizedDescription)")
                    }
                }
            }) {
                Text(product.displayPrice)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var otherItemsSection: some View {
        Section("기타 아이템") {
            itemRow(title: "인벤토리 확장")
            itemRow(title: "내 키링 복제권")
            itemRow(title: "수집하기 티켓")
        }
    }
    
    private func itemRow(title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("100개")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack {
        CoinChargeView(router: NavigationRouter<HomeRoute>())
    }
}
