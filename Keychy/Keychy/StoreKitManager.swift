//
//  StoreKitManager.swift
//  Keychy
//
//  Created by rundo on 10/27/25.
//

import StoreKit

@Observable
class StoreKitManager {
    var products: [Product] = []
    
    private var productIDs = ["coin"]
    
    init() {
        Task {
            await requestProducts()
        }
    }
    
    @MainActor
    func requestProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to retrieving products \(error)")
        }
    }
}
