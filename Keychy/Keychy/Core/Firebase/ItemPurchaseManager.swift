//
//  ItemPurchaseManager.swift
//  Keychy
//
//  아이템 구매 처리 로직 (워크샵, 코인샵 등)
//

import Foundation
import FirebaseFirestore

// MARK: - Purchase Result
enum PurchaseResult {
    case success
    case insufficientCoins
    case failed(String)
}

enum ItemPurchaseError: Error {
    case insufficientCoins
    case userNotFound
    case itemNotFound
    case updateFailed

    var localizedDescription: String {
        switch self {
        case .insufficientCoins:
            return "코인이 부족합니다"
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다"
        case .itemNotFound:
            return "아이템 정보를 찾을 수 없습니다"
        case .updateFailed:
            return "구매 처리 중 오류가 발생했습니다"
        }
    }
}

@MainActor
class ItemPurchaseManager {
    static let shared = ItemPurchaseManager()

    private init() {}

    /// 워크샵 아이템 구매 처리
    /// - Parameters:
    ///   - item: 구매할 아이템 (WorkshopItem 프로토콜 준수)
    ///   - userManager: UserManager 인스턴스
    /// - Returns: PurchaseResult (성공, 코인부족, 실패)
    func purchaseWorkshopItem(_ item: any WorkshopItem, userManager: UserManager) async -> PurchaseResult {
        // 1. 현재 유저 정보 확인
        guard let userId = userManager.currentUser?.id,
              let userCoins = userManager.currentUser?.coin,
              let itemId = item.id else {
            return .failed("사용자 정보를 찾을 수 없습니다")
        }

        // 2. 재화 충분한지 확인
        guard userCoins >= item.workshopPrice else {
            return .insufficientCoins
        }

        // 3. Firebase 업데이트
        let db = Firestore.firestore()
        let userRef = db.collection("User").document(userId)

        do {
            // 현재 문서 읽기
            let snapshot = try await userRef.getDocument()

            guard let data = snapshot.data() else {
                return .failed("사용자 정보를 찾을 수 없습니다")
            }

            let currentCoin = data["coin"] as? Int ?? 0

            // 재화 재확인
            guard currentCoin >= item.workshopPrice else {
                return .insufficientCoins
            }

            // 업데이트할 데이터 준비
            var updateData: [String: Any] = [
                "coin": currentCoin - item.workshopPrice
            ]

            // 아이템 타입에 따라 해당 필드에 추가
            if item is KeyringTemplate {
                updateData["templates"] = FieldValue.arrayUnion([itemId])
            } else if item is Background {
                updateData["backgrounds"] = FieldValue.arrayUnion([itemId])
            } else if item is Carabiner {
                updateData["carabiners"] = FieldValue.arrayUnion([itemId])
            } else if item is Particle {
                updateData["particleEffects"] = FieldValue.arrayUnion([itemId])
            } else if item is Sound {
                updateData["soundEffects"] = FieldValue.arrayUnion([itemId])
            }

            // Firebase 업데이트
            try await userRef.updateData(updateData)

            // 4. UserManager 데이터 갱신
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                userManager.loadUserInfo(uid: userId) { _ in
                    continuation.resume()
                }
            }

            return .success

        } catch {
            print("구매 실패 에러: \(error.localizedDescription)")
            return .failed("구매 처리 중 오류가 발생했습니다")
        }
    }
}
