//
//  RootViewModel+ReviewCheck.swift
//  Keychy
//
//  Created by 길지훈 on 1/15/26.
//

import Foundation
import FirebaseFirestore

extension RootViewModel {
    // MARK: - Review Check

    func checkActiveReview() {
        guard let userId = userManager.currentUser?.id else { return }

        Task {
            let keyringCount = await fetchUserKeyringCount(userId: userId)
            await MainActor.run {
                ReviewManager.shared.checkActive7Days(totalKeyringCount: keyringCount)
            }
        }
    }

    private func fetchUserKeyringCount(userId: String) async -> Int {
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
