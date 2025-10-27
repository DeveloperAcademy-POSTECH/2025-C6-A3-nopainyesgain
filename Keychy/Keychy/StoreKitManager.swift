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
    var purchasedProducts: [Product] = [] //변수 추가

    
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
    
    //Product 를 구입하는 함수
    @MainActor
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(.verified(let transaction)):
            purchasedProducts.append(product)
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
}
