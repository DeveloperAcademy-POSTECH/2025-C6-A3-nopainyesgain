//
//  KeyringCustomizingView+Purchase.swift
//  Keychy
//
//  구매 처리 로직
//

import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - Purchase Logic
extension KeyringCustomizingView {
    /// 구매 처리
    func handlePurchase() async {
        // 1. 현재 유저 정보 확인
        guard let userId = UserManager.shared.currentUser?.id,
              let userCoins = UserManager.shared.currentUser?.coin else {
            return
        }

        // 2. 재화 충분한지 확인
        let totalPrice = totalCartPrice
        if userCoins < totalPrice {
            await MainActor.run {
                // 시트 먼저 닫기
                showPurchaseSheet = false
            }
            // 시트 닫히는 애니메이션 대기
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                showPurchaseFailAlert = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseFailScale = 1.0
                }
            }
            return
        }

        // 3. Firebase 트랜잭션 처리
        let db = Firestore.firestore()
        let userRef = db.collection("User").document(userId)

        do {
            // 장바구니 아이템을 사운드/파티클로 분리
            let soundIds = cartItems.filter { $0.type == .sound }.map { $0.id }
            let particleIds = cartItems.filter { $0.type == .particle }.map { $0.id }

            // 배치 업데이트 (원자성 보장)
            let _ = try await db.runTransaction { (transaction, errorPointer) -> Any? in
                // 현재 유저 데이터 읽기
                let userDocument: DocumentSnapshot
                do {
                    userDocument = try transaction.getDocument(userRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                // 유저 문서가 존재하는지 확인
                guard userDocument.exists else {
                    let error = NSError(
                        domain: "AppErrorDomain",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "유저 문서가 존재하지 않습니다."]
                    )
                    errorPointer?.pointee = error
                    return nil
                }

                // 재화 차감
                transaction.updateData([
                    "coin": FieldValue.increment(Int64(-totalPrice))
                ], forDocument: userRef)

                // 사운드 소유 목록 추가
                if !soundIds.isEmpty {
                    transaction.updateData([
                        "soundEffects": FieldValue.arrayUnion(soundIds)
                    ], forDocument: userRef)
                }

                // 파티클 소유 목록 추가
                if !particleIds.isEmpty {
                    transaction.updateData([
                        "particleEffects": FieldValue.arrayUnion(particleIds)
                    ], forDocument: userRef)
                }

                return nil
            }

            // 4. UserManager 데이터 갱신
            UserManager.shared.loadUserInfo(uid: userId) { _ in }

            // 5. ViewModel의 이펙트 데이터 다시 가져오기 (소유 목록 갱신됨)
            await viewModel.fetchEffects()

            // 6. UI 업데이트 (성공 Alert 표시 및 장바구니 비우기)
            await MainActor.run {
                clearCart()
                showPurchaseSheet = false
                showPurchaseSuccessAlert = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseSuccessScale = 1.0
                }
            }

            // 7. 1.5초 후 Alert 자동으로 닫기
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    purchaseSuccessScale = 0.3
                }
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            await MainActor.run {
                showPurchaseSuccessAlert = false
            }

        } catch {
            await MainActor.run {
                // 시트 먼저 닫기
                showPurchaseSheet = false
            }
            // 시트 닫히는 애니메이션 대기
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
