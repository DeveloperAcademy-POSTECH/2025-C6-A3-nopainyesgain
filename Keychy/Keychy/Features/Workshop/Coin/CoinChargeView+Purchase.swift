//
//  CoinChargeView+Purchase.swift
//  Keychy
//
//  코인으로 구매하는 아이템 처리 로직
//

import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - Purchase Logic
extension CoinChargeView {
    /// 구매 처리
    func handlePurchase() async {
        guard let item = selectedItem else { return }
        
        // 1. 현재 유저 정보 확인
        guard let userId = UserManager.shared.currentUser?.id,
              let userCoins = UserManager.shared.currentUser?.coin else {
            return
        }

        // 2. 재화 충분한지 확인
        if userCoins < item.price {
            await MainActor.run {
                showPurchaseSheet = false
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                showPurchaseFailAlert = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseFailScale = 1.0
                }
            }
            return
        }

        // 3. Firebase 직접 업데이트 (트랜잭션 대신)
        let db = Firestore.firestore()
        let userRef = db.collection("User").document(userId)

        do {
            // 현재 문서 읽기
            let snapshot = try await userRef.getDocument()
            
            guard let data = snapshot.data() else {
                throw NSError(domain: "AppErrorDomain", code: -1, userInfo: nil)
            }
            
            let currentCoin = data["coin"] as? Int ?? 0
            let currentCopyVoucher = data["copyVoucher"] as? Int ?? 0
            let currentMaxKeyringCount = data["maxKeyringCount"] as? Int ?? 0
            
            // 재화 확인
            guard currentCoin >= item.price else {
                throw NSError(domain: "AppErrorDomain", code: -2, userInfo: nil)
            }
            
            // 업데이트할 데이터 준비
            var updateData: [String: Any] = [
                "coin": currentCoin - item.price
            ]
            
            switch item {
            case .inventoryExpansion:
                updateData["maxKeyringCount"] = currentMaxKeyringCount + 10
                
            case .copyVoucher10:
                updateData["copyVoucher"] = currentCopyVoucher + 10
            }
            
            // Firebase 업데이트
            try await userRef.updateData(updateData)

            // 4. UserManager 데이터 갱신
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                UserManager.shared.loadUserInfo(uid: userId) { _ in
                    continuation.resume()
                }
            }

            // 5. UI 업데이트 (성공 Alert 표시)
            await MainActor.run {
                showPurchaseSheet = false
                showPurchaseSuccessAlert = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseSuccessScale = 1.0
                }
            }

        } catch {
            print("구매 실패 에러: \(error.localizedDescription)")
            await MainActor.run {
                showPurchaseSheet = false
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                showPurchaseFailAlert = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseFailScale = 1.0
                }
            }
        }
    }
}
