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
            try await db.runTransaction { (transaction, errorPointer) -> Any? in
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

                // 모든 업데이트를 하나의 딕셔너리로 합치기
                var updates: [String: Any] = [
                    "coin": FieldValue.increment(Int64(-totalPrice))
                ]

                // 사운드 소유 목록 추가
                if !soundIds.isEmpty {
                    updates["soundEffects"] = FieldValue.arrayUnion(soundIds)
                }

                // 파티클 소유 목록 추가
                if !particleIds.isEmpty {
                    updates["particleEffects"] = FieldValue.arrayUnion(particleIds)
                }

                // 한 번에 업데이트!
                transaction.updateData(updates, forDocument: userRef)

                return "success"
            }

            // 4. 시트 닫고 구매 중 프로그레스 표시
            await MainActor.run {
                showPurchaseSheet = false
                showPurchaseProgress = true
            }

            // 5. Firebase 커밋이 완전히 완료될 때까지 대기
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            // 6. UserManager만 갱신 (fetchEffects 호출하지 않음)
            // -> fetchEffects()를 호출하면 소유/미소유로 리스트가 재배열되어 ForEach가 재구성됨
            // -> 선택된 아이템의 위치가 바뀌면서 텍스트 깨짐 및 스크롤 끊김 발생
            // -> UserManager만 갱신하면 isOwned() 체크만 업데이트되어 UI 스타일만 변경됨
            UserManager.shared.loadUserInfo(uid: userId) { _ in }

            // 7. UserManager 갱신 완료 대기
            try? await Task.sleep(nanoseconds: 500_000_000)

            // 8. UI 업데이트 (프로그레스 닫고 성공 Alert 표시 및 장바구니 비우기)
            await MainActor.run {
                clearCart()
                showPurchaseProgress = false
                showPurchaseSuccessAlert = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchaseSuccessScale = 1.0
                }
            }

            // 9. 1.5초 후 Alert 자동으로 닫기
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

        } catch _ as NSError {
            await MainActor.run {
                // 프로그레스 닫기
                showPurchaseProgress = false
            }
            // 애니메이션 대기
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
