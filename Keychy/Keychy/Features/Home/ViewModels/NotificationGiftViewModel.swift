//
//  NotificationGiftViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/16/24.
//

import SwiftUI
import FirebaseFirestore
import SpriteKit

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
    
    /// 캐시된 키링 이미지
    var cachedKeyringImage: UIImage?
    
    /// 씬 캡쳐 중 여부
    var isCapturing: Bool = false
    
    /// 이미지 보여줄지 여부
    var showContent: Bool = false

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

    /// 알림을 읽음 처리 (postOfficeId로 조회)
    func markNotificationAsRead(postOfficeId: String) {
        db.collection("Notifications")
            .whereField("postOfficeId", isEqualTo: postOfficeId)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("알림 조회 실패: \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("알림을 찾을 수 없음: \(postOfficeId)")
                    return
                }

                // 이미 읽음 상태면 스킵
                if let isRead = document.data()["isRead"] as? Bool, isRead {
                    return
                }

                // 읽음 처리
                self.db.collection("Notifications")
                    .document(document.documentID)
                    .updateData(["isRead": true]) { error in
                        if let error = error {
                            print("알림 읽음 처리 실패: \(error.localizedDescription)")
                        } else {
                            print("알림 읽음 처리 완료: \(document.documentID)")
                            // UserManager의 updateBadgeCount 호출
                            Task { @MainActor in
                                UserManager.shared.updateBadgeCount()
                            }
                        }
                    }
            }
    }

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
    
    // 캐시된 이미지 로드
    func loadCachedImage(keyring: Keyring) {
        guard let keyringID = keyring.documentId else {
            print("키링 ID 없음")
            showContent = true
            return
        }
        
        // 1. 캐시에서 이미지 로드
        if let imageData = KeyringImageCache.shared.load(for: keyringID, type: .gift),
           let image = UIImage(data: imageData) {
            self.cachedKeyringImage = image
            withAnimation(.easeIn(duration: 0.3)) {
                self.showContent = true
            }
        } else {
            // 2. 캐시가 없으면 백그라운드에서 이미지 생성
            isCapturing = true
            
            Task.detached(priority: .userInitiated) { [weak self] in
                await self?.generateAndCacheImage(keyring: keyring)
            }
        }
    }
    
    // 씬 이미지 생성 및 캐시
    func generateAndCacheImage(keyring: Keyring) async {
        guard let keyringID = keyring.documentId else {
            await MainActor.run {
                showContent = true
                isCapturing = false
            }
            return
        }
        
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var loadingCompleted = false
            
            let scene = KeyringCellScene(
                ringType: ringType,
                chainType: chainType,
                bodyImage: keyring.bodyImage,
                targetSize: CGSize(width: 304, height: 490),
                customBackgroundColor: .clear,
                zoomScale: 1.9,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.scaleMode = .aspectFill
            scene.backgroundColor = .clear
            
            let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
            view.allowsTransparency = true
            view.presentScene(scene)
            
            Task {
                var waitTime = 0.0
                while !loadingCompleted && waitTime < 5.0 {
                    try? await Task.sleep(for: .seconds(0.1))
                    waitTime += 0.1
                }
                
                guard loadingCompleted else {
                    await MainActor.run {
                        self.showContent = true
                        self.isCapturing = false
                    }
                    continuation.resume()
                    return
                }
                
                try? await Task.sleep(for: .seconds(0.2))
                
                if let pngData = await scene.captureToPNG(),
                   !pngData.isEmpty,
                   let image = UIImage(data: pngData) {
                    // 캐시에 저장
                    KeyringImageCache.shared.save(pngData: pngData, for: keyringID, type: .gift)
                    
                    // UI 업데이트
                    await MainActor.run {
                        self.cachedKeyringImage = image
                        withAnimation(.easeIn(duration: 0.3)) {
                            self.showContent = true
                            self.isCapturing = false
                        }
                    }
                } else {
                    print("PNG 캡처 실패: \(keyring.name)")
                    await MainActor.run {
                        self.showContent = true
                        self.isCapturing = false
                    }
                }
                
                continuation.resume()
            }
        }
    }
}
