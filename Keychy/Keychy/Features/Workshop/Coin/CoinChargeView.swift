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
    
    @State private var currentCherry: Int = 6000
    
    var body: some View {
        List {
            currentCherrySection
            cherrySection
            otherItemsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("재화 구매")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sections
extension CoinChargeView {
    private var currentCherrySection: some View {
        Section {
            Label {
                HStack {
                    Text("현재 보유한 체리")
                    Spacer()
                    Text("\(currentCherry)")
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                }
            } icon: {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.red)
            }
            .font(.callout)
        }
    }
    
    private var cherrySection: some View {
        Section("체리") {
            ForEach(store.products, id: \.id) { product in
                cherryRow(for: product)
            }
        }
    }
    
    private func cherryRow(for product: Product) -> some View {
        HStack {
            Label("\(product.displayName)개", systemImage: "leaf.fill")
                .foregroundStyle(.red)
            
            Spacer()
            
            Button(product.displayPrice) {
                Task {
                    do {
                        _ = try await store.purchase(product)
                        // TODO: 구매 성공 시 처리 (ex. 체리 증가)
                    } catch {
                        print("구매 실패: \(error.localizedDescription)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.black)
            .foregroundStyle(.white)
        }
        .listRowSeparator(.visible)
    }
    
    private var otherItemsSection: some View {
        Section("기타 아이템") {
            ForEach(otherItems, id: \.title) { item in
                itemRow(item)
            }
        }
    }
    
    private var otherItems: [(title: String, cost: Int)] {
        [
            ("인벤토리 확장", 100),
            ("내 키링 복제권", 100),
            ("수집하기 티켓", 100)
        ]
    }
    
    private func itemRow(_ item: (title: String, cost: Int)) -> some View {
        HStack {
            Text(item.title)
            Spacer()
            Button {
                // TODO: 아이템 구매 로직
            } label: {
                Label("\(item.cost)개", systemImage: "leaf.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .tint(.black)
            .foregroundStyle(.white)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        CoinChargeView(router: NavigationRouter<HomeRoute>())
    }
}
