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
    
    // MARK: - Festival에서 Workshop으로 갔을 때 사용
    var isFromFestivalTab: Bool = false
    var onKeyringCompleteFromFestival: ((NavigationRouter<WorkshopRoute>) -> Void)?
    
    // MARK: - 선택된 키링 디테일
    var selectedShowcaseKeyring: ShowcaseFestivalKeyring?
    var selectedKeyringForDetail: Keyring?

    // MARK: - 시트 관련
    var showKeyringSheet = false
    var selectedGridIndex: Int = 0
    var selectedKeyringForUpload: Keyring?  // 시트에서 선택한 키링 (완료 전)
    
    // MARK: - 페스티벌에서 사용하는 유저 정보 관련
    var maxKeyringCount: Int = 100 // 기본값
    var coin: Int = 0
    var copyVoucher: Int = 0

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

    /// isEditing 자동 만료 시간 (2분)
    private let editingTimeoutSeconds: TimeInterval = 2 * 60

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

            // 최신순으로 정렬 (createdAt 기준 내림차순)
            userKeyrings = loadedKeyrings.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("❌ Failed to fetch user keyrings: \(error.localizedDescription)")
        }
    }

    // MARK: - 쇼케이스 키링 업데이트

    /// 선택한 키링으로 쇼케이스 키링 추가/업데이트
    @MainActor
    func addOrUpdateShowcaseKeyring(at gridIndex: Int, with userKeyring: Keyring) async {
        guard let keyringDocId = userKeyring.documentId else {
            print("❌ documentId가 없습니다")
            return
        }

        isLoading = true

        let data: [String: Any] = [
            "name": userKeyring.name,
            "authorId": userKeyring.authorId,
            "bodyImageURL": userKeyring.bodyImage,
            "gridIndex": gridIndex,
            "isEditing": false,
            "editingUserNickname": "",
            "keyringId": keyringDocId,
            "memo": userKeyring.memo ?? "",
            "particleId": userKeyring.particleId,
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

            // 원본 Keyring의 isPublished를 true로 업데이트
            try await db.collection("Keyring").document(keyringDocId).updateData([
                "isPublished": true
            ])
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
            var updateData: [String: Any] = ["isEditing": isEditing]

            if isEditing {
                // 수정 시작 시 현재 사용자 닉네임과 시작 시간 저장
                let nickname = UserManager.shared.currentUser?.nickname ?? "알 수 없음"
                updateData["editingUserNickname"] = nickname
                updateData["editingStartedAt"] = Timestamp(date: Date())
            } else {
                // 수정 종료 시 닉네임과 시작 시간 초기화
                updateData["editingUserNickname"] = ""
                updateData["editingStartedAt"] = FieldValue.delete()
            }

            try await db.collection(collectionName).document(existingKeyring.id).updateData(updateData)
        } catch {
            print("❌ Failed to update isEditing: \(error.localizedDescription)")
        }
    }

    /// Heartbeat: editingStartedAt 시간 갱신 (시트가 열려있는 동안 주기적으로 호출)
    @MainActor
    func refreshEditingTimestamp(at gridIndex: Int) async {
        guard let existingKeyring = keyring(at: gridIndex),
              existingKeyring.isEditing else { return }

        do {
            try await db.collection(collectionName).document(existingKeyring.id).updateData([
                "editingStartedAt": Timestamp(date: Date())
            ])
        } catch {
            print("❌ Failed to refresh editing timestamp: \(error.localizedDescription)")
        }
    }

    /// 닉네임 마스킹 (첫글자, 마지막글자 제외 나머지 *)
    func maskedNickname(_ nickname: String) -> String {
        guard nickname.count > 2 else { return nickname }

        let characters = Array(nickname)
        let first = characters.first!
        let last = characters.last!
        let middleCount = characters.count - 2
        let masked = String(repeating: "*", count: middleCount)

        return "\(first)\(masked)\(last)"
    }

    /// 해당 셀이 다른 사람에 의해 수정 중인지 확인 (시간 만료 체크 포함)
    func isBeingEditedByOthers(at gridIndex: Int) -> Bool {
        guard let keyring = keyring(at: gridIndex) else { return false }

        // isEditing이 false면 수정 중이 아님
        guard keyring.isEditing else { return false }

        // 내가 수정 중인 경우는 제외
        guard keyring.authorId != UserManager.shared.userUID else { return false }

        // 시간 만료 체크: editingStartedAt이 없거나 5분 이상 경과하면 수정 중이 아닌 것으로 간주
        if let startedAt = keyring.editingStartedAt {
            let elapsedTime = Date().timeIntervalSince(startedAt)
            if elapsedTime > editingTimeoutSeconds {
                // 만료된 경우 - 자동으로 isEditing을 false로 업데이트
                Task {
                    await clearExpiredEditing(at: gridIndex)
                }
                return false
            }
        } else {
            // editingStartedAt이 없으면 만료된 것으로 간주
            return false
        }

        return true
    }

    /// 만료된 isEditing 상태 초기화
    @MainActor
    private func clearExpiredEditing(at gridIndex: Int) async {
        guard let existingKeyring = keyring(at: gridIndex) else { return }

        do {
            try await db.collection(collectionName).document(existingKeyring.id).updateData([
                "isEditing": false,
                "editingUserNickname": "",
                "editingStartedAt": FieldValue.delete()
            ])
            print("🕐 Cleared expired editing state at gridIndex: \(gridIndex)")
        } catch {
            print("❌ Failed to clear expired editing: \(error.localizedDescription)")
        }
    }

    // MARK: - 쇼케이스 키링 삭제

    /// 쇼케이스 키링 회수 (필드 초기화)
    @MainActor
    func deleteShowcaseKeyring(at gridIndex: Int) async {
        guard let existingKeyring = keyring(at: gridIndex) else { return }

        isLoading = true

        do {
            // 원본 Keyring의 isPublished를 false로 업데이트
            let keyringId = existingKeyring.keyringId
            if keyringId != "none" {
                try await db.collection("Keyring").document(keyringId).updateData([
                    "isPublished": false
                ])
            }

            // 문서 삭제 대신 필드 초기화
            let resetData: [String: Any] = [
                "name": "",
                "authorId": "",
                "bodyImageURL": "",
                "gridIndex": gridIndex,
                "isEditing": false,
                "editingUserNickname": "",
                "keyringId": "none",
                "memo": "",
                "particleId": "none",
                "soundId": "none",
                "votes": 0
            ]
            try await db.collection(collectionName).document(existingKeyring.id).setData(resetData)
            // 리스너가 자동으로 업데이트함
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to reset showcase keyring: \(error.localizedDescription)")
        }

        isLoading = false
    }
    
    // MARK: - 유저 닉네임 가져오기
    func fetchUserName(userId: String, completion: @escaping (String) -> Void) {
        db.collection("User")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("작성자 정보 로드 에러: \(error.localizedDescription)")
                    completion("알 수 없음")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let nickname = data["nickname"] as? String else {
                    completion("알 수 없음")
                    return
                }
                
                completion(nickname)
            }
    }
}
