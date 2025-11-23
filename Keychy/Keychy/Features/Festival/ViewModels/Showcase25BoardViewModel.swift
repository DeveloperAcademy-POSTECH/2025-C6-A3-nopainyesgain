//
//  Showcase25BoardViewModel.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import Foundation
import FirebaseFirestore

@Observable
class Showcase25BoardViewModel {
    var keyrings: [ShowcaseFestivalKeyring] = []
    var isLoading = false
    var error: String?

    /// gridIndex를 key로 하는 키링 딕셔너리 (빠른 조회용)
    var keyringsByGridIndex: [Int: ShowcaseFestivalKeyring] {
        Dictionary(uniqueKeysWithValues: keyrings.map { ($0.gridIndex, $0) })
    }

    private let db = Firestore.firestore()
    private let collectionName = "ShowcaseFestivalKeyring"

    init() {
        Task {
            await fetchKeyrings()
        }
    }

    /// Firebase에서 키링 데이터 로드
    @MainActor
    func fetchKeyrings() async {
        isLoading = true
        error = nil

        do {
            let snapshot = try await db.collection(collectionName).getDocuments()
            keyrings = snapshot.documents.compactMap { ShowcaseFestivalKeyring(document: $0) }
            print("✅ Fetched \(keyrings.count) festival keyrings")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to fetch festival keyrings: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// 특정 gridIndex에 해당하는 키링 반환
    func keyring(at gridIndex: Int) -> ShowcaseFestivalKeyring? {
        keyringsByGridIndex[gridIndex]
    }
}
