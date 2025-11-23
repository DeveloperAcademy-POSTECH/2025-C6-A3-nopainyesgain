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
    // MARK: - 쇼케이스 키링 (Firebase)
    var showcaseKeyrings: [ShowcaseFestivalKeyring] = []
    var isLoading = false
    var error: String?

    // MARK: - 사용자 키링 (내 컬렉션)
    var userKeyrings: [Keyring] = []

    // MARK: - 시트 관련
    var showKeyringSheet = false
    var selectedGridIndex: Int = 0
    var selectedKeyringForUpload: Keyring?  // 시트에서 선택한 키링 (완료 전)

    // MARK: - 줌 관련
    var currentZoom: CGFloat = 1.5
    private let buttonVisibleZoom: CGFloat = 1.5 // 이 값을 낮출수록 더 멀리서도 보임

    var showButtons: Bool {
        currentZoom >= buttonVisibleZoom
    }

    /// gridIndex를 key로 하는 키링 딕셔너리 (빠른 조회용)
    var keyringsByGridIndex: [Int: ShowcaseFestivalKeyring] {
        Dictionary(uniqueKeysWithValues: showcaseKeyrings.map { ($0.gridIndex, $0) })
    }

    private let db = Firestore.firestore()
    private let collectionName = "ShowcaseFestivalKeyring"

    init() {
        Task {
            await fetchShowcaseKeyrings()
            await fetchUserKeyrings()
        }
    }

    // MARK: - 쇼케이스 키링 로드

    /// Firebase에서 쇼케이스 키링 데이터 로드
    @MainActor
    func fetchShowcaseKeyrings() async {
        isLoading = true
        error = nil

        do {
            let snapshot = try await db.collection(collectionName).getDocuments()
            showcaseKeyrings = snapshot.documents.compactMap { ShowcaseFestivalKeyring(document: $0) }
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to fetch showcase keyrings: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// 특정 gridIndex에 해당하는 키링 반환
    func keyring(at gridIndex: Int) -> ShowcaseFestivalKeyring? {
        keyringsByGridIndex[gridIndex]
    }

    /// 해당 쇼케이스 키링이 내 키링인지 확인
    func isMyKeyring(at gridIndex: Int) -> Bool {
        guard let showcaseKeyring = keyring(at: gridIndex) else { return false }
        return showcaseKeyring.authorId == UserManager.shared.userUID
    }

    // MARK: - 사용자 키링 로드

    /// 사용자 보유 키링 로드
    @MainActor
    func fetchUserKeyrings() async {
        let uid = UserManager.shared.userUID

        do {
            // User 문서에서 키링 ID 목록 가져오기
            let userDoc = try await db.collection("User").document(uid).getDocument()
            guard let data = userDoc.data(),
                  let keyringIds = data["keyrings"] as? [String] else {
                return
            }

            // 키링 ID로 Keyring 문서들 로드
            var loadedKeyrings: [Keyring] = []
            for keyringId in keyringIds {
                let keyringDoc = try await db.collection("Keyring").document(keyringId).getDocument()
                if let data = keyringDoc.data(),
                   let keyring = Keyring(documentId: keyringDoc.documentID, data: data) {
                    loadedKeyrings.append(keyring)
                }
            }

            userKeyrings = loadedKeyrings
        } catch {
            print("❌ Failed to fetch user keyrings: \(error.localizedDescription)")
        }
    }

    // MARK: - 쇼케이스 키링 업데이트

    /// 선택한 키링으로 쇼케이스 키링 추가/업데이트
    @MainActor
    func addOrUpdateShowcaseKeyring(at gridIndex: Int, with userKeyring: Keyring) async {
        isLoading = true

        let data: [String: Any] = [
            "authorId": UserManager.shared.userUID,
            "bodyImageURL": userKeyring.bodyImage,
            "gridIndex": gridIndex,
            "isEditing": false,
            "keyringId": userKeyring.id.uuidString,
            "memo": userKeyring.memo ?? "",
            "particleid": userKeyring.particleId,
            "soundId": userKeyring.soundId,
            "votes": 0
        ]

        do {
            // 기존 문서 확인
            if let existingKeyring = keyring(at: gridIndex) {
                // 업데이트
                try await db.collection(collectionName).document(existingKeyring.id).setData(data)
            } else {
                // 새로 추가
                try await db.collection(collectionName).addDocument(data: data)
            }

            // 데이터 새로고침
            await fetchShowcaseKeyrings()
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to update showcase keyring: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - 쇼케이스 키링 삭제

    /// 쇼케이스 키링 회수 (삭제)
    @MainActor
    func deleteShowcaseKeyring(at gridIndex: Int) async {
        guard let existingKeyring = keyring(at: gridIndex) else { return }

        isLoading = true

        do {
            try await db.collection(collectionName).document(existingKeyring.id).delete()

            // 데이터 새로고침
            await fetchShowcaseKeyrings()
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to delete showcase keyring: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
