//
//  NotificationGiftViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/16/24.
//

import SwiftUI
import FirebaseFirestore

@Observable
class NotificationGiftViewModel {
    // MARK: - Properties

    /// 키링 ID
    var keyringId: String = ""

    /// 키링 이름
    var keyringName: String = ""

    /// 수신자 닉네임
    var recipientNickname: String = ""

    /// 제작자 이름
    var authorName: String = ""

    /// 완료 날짜
    var completedDate: Date = Date()

    /// 로딩 중 여부
    var isLoading: Bool = true

    /// 로딩 에러 메시지
    var loadError: String?

    /// 키링 데이터
    var keyring: Keyring?

    // MARK: - Private Properties

    private let db = Firestore.firestore()

    // MARK: - Computed Properties

    /// 포맷된 날짜 문자열
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: completedDate)
    }

    // MARK: - Methods

    /// 선물 데이터 가져오기
    func fetchGiftData(postOfficeId: String, viewModel: CollectionViewModel) {
        isLoading = true
        loadError = nil

        // 1. PostOffice 조회
        db.collection("PostOffice").document(postOfficeId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            guard let data = snapshot?.data(),
                  let keyringId = data["keyringId"] as? String,
                  let receiverId = data["receiverId"] as? String,
                  let endedTimestamp = data["endedAt"] as? Timestamp else {
                DispatchQueue.main.async { [weak self] in
                    self?.loadError = "선물 정보를 찾을 수 없습니다"
                    self?.isLoading = false
                }
                return
            }

            DispatchQueue.main.async { [weak self] in
                self?.completedDate = endedTimestamp.dateValue()
                self?.keyringId = keyringId
            }

            // 2. Keyring 조회
            viewModel.fetchKeyringById(keyringId: keyringId) { [weak self] fetchedKeyring in
                guard let self = self else { return }

                guard let keyring = fetchedKeyring else {
                    DispatchQueue.main.async { [weak self] in
                        self?.loadError = "키링 정보를 찾을 수 없습니다"
                        self?.isLoading = false
                    }
                    return
                }

                DispatchQueue.main.async { [weak self] in
                    self?.keyring = keyring
                    self?.keyringName = keyring.name
                }

                // 3. 제작자 이름 로드
                viewModel.fetchUserName(userId: keyring.authorId) { [weak self] name in
                    DispatchQueue.main.async { [weak self] in
                        self?.authorName = name
                    }
                }

                // 4. 수신자 닉네임 로드
                viewModel.fetchUserName(userId: receiverId) { [weak self] nickname in
                    DispatchQueue.main.async { [weak self] in
                        self?.recipientNickname = nickname
                        self?.isLoading = false
                    }
                }
            }
        }
    }
    
    /// 씬을 캡처해서 캐시에 저장
    func cacheKeyringImage(from scene: KeyringCellScene, keyring: Keyring) async {
        guard let keyringID = keyring.documentId else { return }
        
        // 렌더링 완료 대기
        try? await Task.sleep(for: .seconds(0.2))
        
        if let pngData = await scene.captureToPNG(),
           !pngData.isEmpty {
            KeyringImageCache.shared.save(pngData: pngData, for: keyringID)
        }
    }
}
