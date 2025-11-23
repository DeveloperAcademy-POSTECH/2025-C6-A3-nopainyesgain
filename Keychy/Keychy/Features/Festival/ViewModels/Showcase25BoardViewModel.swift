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
    var selectedKeyringIndex: Int = 0

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

    /// gridIndex를 key로 하는 키링 딕셔너리 (빠른 조회용, 중복 시 마지막 값 사용)
    var keyringsByGridIndex: [Int: ShowcaseFestivalKeyring] {
        Dictionary(showcaseKeyrings.map { ($0.gridIndex, $0) }, uniquingKeysWith: { _, new in new })
    }

    private let db = Firestore.firestore()
    private let collectionName = "ShowcaseFestivalKeyring"
    private var listener: ListenerRegistration?

    init() {
        Task {
            await fetchUserKeyrings()
        }
    }

    deinit {
        stopListening()
    }

    // MARK: - Snapshot Listener

    /// 실시간 리스너 시작
    func startListening() {
        guard listener == nil else { return }

        listener = db.collection(collectionName).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Snapshot listener error: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else { return }

            // 변경사항 처리
            snapshot.documentChanges.forEach { change in
                DispatchQueue.main.async {
                    switch change.type {
                    case .added:
                        // 새로운 키링 추가
                        if let keyring = ShowcaseFestivalKeyring(document: change.document) {
                            if !self.showcaseKeyrings.contains(where: { $0.id == keyring.id }) {
                                self.showcaseKeyrings.append(keyring)
                            }
                        }
                    case .modified:
                        // bodyImageURL 변경 시 업데이트
                        if let keyring = ShowcaseFestivalKeyring(document: change.document),
                           let index = self.showcaseKeyrings.firstIndex(where: { $0.id == keyring.id }) {
                            self.showcaseKeyrings[index] = keyring
                        }
                    case .removed:
                        // 키링 삭제
                        self.showcaseKeyrings.removeAll { $0.id == change.document.documentID }
                    }
                }
            }
        }

        print("✅ Started listening to ShowcaseFestivalKeyring")
    }

    /// 실시간 리스너 중지
    func stopListening() {
        listener?.remove()
        listener = nil
        print("🛑 Stopped listening to ShowcaseFestivalKeyring")
    }

    // MARK: - 쇼케이스 키링 로드

    /// 특정 gridIndex에 해당하는 키링 반환
    func keyring(at gridIndex: Int) -> ShowcaseFestivalKeyring? {
        keyringsByGridIndex[gridIndex]
    }
    
    /// 특정 ShowcaseFestivalKeyring을 keyring으로 변환
    @MainActor
    func convertToKeyring(from showcaseKeyring: ShowcaseFestivalKeyring) async -> Keyring? {
        do {
            let keyringDoc = try await db.collection("Keyring").document(showcaseKeyring.keyringId).getDocument()
            
            guard let data = keyringDoc.data() else {
                return nil
            }
            
            return Keyring(documentId: keyringDoc.documentID, data: data)
        } catch {
            return nil
        }
    }

    /// 해당 쇼케이스 키링이 내 키링인지 확인
    func isMyKeyring(at gridIndex: Int) -> Bool {
        guard let showcaseKeyring = keyring(at: gridIndex) else { return false }
        return showcaseKeyring.authorId == UserManager.shared.userUID
    }
    
    /// selectedKeyringIndex를 기반으로 Keyring 가져오기
    @MainActor
    func getSelectedKeyring() async -> Keyring? {
        // selectedKeyringIndex로 ShowcaseFestivalKeyring 가져오기
        guard let showcaseKeyring = keyring(at: selectedKeyringIndex) else {
            return nil
        }
        
        // ShowcaseFestivalKeyring을 Keyring으로 변환
        return await convertToKeyring(from: showcaseKeyring)
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
            // 리스너가 자동으로 업데이트함
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to update showcase keyring: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - isEditing 상태 업데이트

    /// 특정 그리드의 isEditing 상태 업데이트
    @MainActor
    func updateIsEditing(at gridIndex: Int, isEditing: Bool) async {
        guard let existingKeyring = keyring(at: gridIndex) else { return }

        do {
            try await db.collection(collectionName).document(existingKeyring.id).updateData([
                "isEditing": isEditing
            ])
        } catch {
            print("❌ Failed to update isEditing: \(error.localizedDescription)")
        }
    }

    /// 해당 셀이 다른 사람에 의해 수정 중인지 확인
    func isBeingEditedByOthers(at gridIndex: Int) -> Bool {
        guard let keyring = keyring(at: gridIndex) else { return false }
        // isEditing이 true이고, 내가 수정 중인게 아닌 경우
        return keyring.isEditing && keyring.authorId != UserManager.shared.userUID
    }

    // MARK: - 쇼케이스 키링 삭제

    /// 쇼케이스 키링 회수 (삭제)
    @MainActor
    func deleteShowcaseKeyring(at gridIndex: Int) async {
        guard let existingKeyring = keyring(at: gridIndex) else { return }

        isLoading = true

        do {
            try await db.collection(collectionName).document(existingKeyring.id).delete()
            // 리스너가 자동으로 업데이트함
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to delete showcase keyring: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
