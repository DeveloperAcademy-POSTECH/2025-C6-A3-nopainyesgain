//
//  KeyringCompleteView+ReviewCheck.swift
//  Keychy
//
//  Created by 길지훈 on 1/15/26.
//

import Foundation
import FirebaseFirestore

extension KeyringCompleteView {
    // MARK: - Review Check
    func checkReviewTriggers() {
        // 템플릿 사용 기록
        reviewManager.trackTemplateUsage(templateId: viewModel.templateId)

        // 키링 개수 체크 (Firebase에서 조회)
        Task {
            let keyringCount = await fetchUserKeyringCount()
            await MainActor.run {
                reviewManager.checkKeyring5(totalKeyringCount: keyringCount)
            }
        }
    }

    func fetchUserKeyringCount() async -> Int {
        guard let userId = userManager.currentUser?.id else { return 0 }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("Keyring")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            return snapshot.documents.count
        } catch {
            return 0
        }
    }
}
