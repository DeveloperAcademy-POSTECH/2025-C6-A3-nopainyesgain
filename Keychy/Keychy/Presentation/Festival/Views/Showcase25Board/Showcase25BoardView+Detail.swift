//
//  Showcase25BoardView+Detail.swift
//  Keychy
//
//  Created by rundo on 11/24/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Detail/Conversion 관련 Extension

extension Showcase25BoardView {

    // MARK: - Fetch Keyring from Firestore and Navigate

    func fetchAndNavigateToKeyringDetail(keyringId: String) {
        guard keyringId != "none" else {
            print("유효하지 않은 keyringId")
            return
        }

        Task {
            do {
                // 1. Firestore에서 실제 Keyring 문서 가져오기
                let document = try await Firestore.firestore()
                    .collection("Keyring")
                    .document(keyringId)
                    .getDocument()

                guard document.exists, let data = document.data() else {
                    print("Keyring 문서를 찾을 수 없습니다")
                    return
                }

                // 2. Keyring 모델로 변환
                if let keyring = Keyring(documentId: document.documentID, data: data) {
                    // 3. DetailView로 이동 (Main thread에서 실행)
                    await MainActor.run {
                        festivalRouter.push(.festivalKeyringDetailView(keyring))
                    }
                } else {
                    print("Keyring 변환 실패")
                }
            } catch {
                print("Keyring 데이터 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }

    func testFirestoreKeyringExists(keyringId: String) {
        Task {
            do {
                let document = try await Firestore.firestore()
                    .collection("Keyring")
                    .document(keyringId)
                    .getDocument()

                print("""

                Firestore 조회 테스트
                =====================================
                keyringId: \(keyringId)
                document.exists: \(document.exists)
                documentID: \(document.documentID)
                data 필드 개수: \(document.data()?.keys.count ?? 0)
                =====================================

                """)

                if let data = document.data() {
                    print("문서 필드:")
                    for (key, value) in data {
                        print("  - \(key): \(value)")
                    }
                }
            } catch {
                print("테스트 실패: \(error)")
            }
        }
    }
}
