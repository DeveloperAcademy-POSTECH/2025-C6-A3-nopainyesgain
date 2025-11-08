import Foundation
import StoreKit
import Combine

@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()

        Task {
            await fetchProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // Transaction Updates 리스너
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // 구매 처리
                    await self.handleVerifiedTransaction(transaction)

                    // 트랜잭션 완료
                    await transaction.finish()
                } catch {
                    print("트랜잭션 업데이트 처리 실패: \(error)")
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // 검증된 트랜잭션 처리
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        guard let product = StoreProduct(rawValue: transaction.productID) else {
            print("알 수 없는 상품 ID: \(transaction.productID)")
            return
        }

        print("\(product.coinAmount)개 트랜잭션 처리")

        // UserManager를 통해 코인 업데이트
        await withCheckedContinuation { continuation in
            UserManager.shared.updateCoin(by: product.coinAmount) { success in
                if success {
                    print("코인 지급 완료")
                } else {
                    print("코인 지급 실패")
                }
                continuation.resume()
            }
        }
    }
    
    // 1. 상품 불러오기
    @MainActor
    func fetchProducts() async {
        do {
            let productIDs = StoreProduct.allCases.map { $0.rawValue }

            let storeProducts = try await Product.products(for: productIDs)

            // StoreProduct enum의 순서대로 정렬
            products = storeProducts.sorted { product1, product2 in
                guard let index1 = StoreProduct.allCases.firstIndex(where: { $0.rawValue == product1.id }),
                      let index2 = StoreProduct.allCases.firstIndex(where: { $0.rawValue == product2.id }) else {
                    return false
                }
                return index1 < index2
            }
            
            print("정렬된 상품: \(products.map(\.id))")
            print("상품 개수: \(products.count)")

            if products.isEmpty {
                print("경고: 상품이 비어있습니다!")
                print("Xcode > Product > Scheme > Edit Scheme > Run > Options 에서")
                print("StoreKit Configuration이 'StoreKit.storekit'으로 설정되어 있는지 확인하세요")
            }
        } catch {
            print("상품 불러오기 실패: \(error)")
            print("에러 상세: \(error.localizedDescription)")
        }
    }
    
    // 2. 구매 실행
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            do {
                let transaction = try checkVerified(verification)
                await handleVerifiedTransaction(transaction)
                await transaction.finish()
            } catch {
                print("검증 실패")
                throw PurchaseError.verificationFailed
            }

        case .userCancelled:
            print("사용자 취소")
            throw PurchaseError.userCancelled

        case .pending:
            print("결제 승인 대기 중")
            throw PurchaseError.pending

        @unknown default:
            print("알 수 없는 결제 결과")
            throw PurchaseError.unknown
        }
    }
}

// MARK: - Purchase Errors
enum PurchaseError: LocalizedError {
    case verificationFailed
    case userCancelled
    case pending
    case unknown
    case invalidProduct

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "구매 검증에 실패했습니다."
        case .userCancelled:
            return "구매가 취소되었습니다."
        case .pending:
            return "결제 승인 대기 중입니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        case .invalidProduct:
            return "유효하지 않은 상품입니다."
        }
    }
}
