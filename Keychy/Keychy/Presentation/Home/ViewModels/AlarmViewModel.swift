//
//  AlarmViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/15/24.
//

import SwiftUI
import FirebaseFirestore
import UserNotifications
import SpriteKit

@Observable
class AlarmViewModel {
    // MARK: - Properties
    /// 알림 데이터
    var notifications: [KeychyNotification] = []

    /// 알림 로딩 상태
    var isLoadingNotifications: Bool = false

    /// 알림이 비어있는지 여부
    var isNotiEmpty: Bool = true

    /// 푸시 알림이 꺼져있는지 여부
    var isNotiOff: Bool = false

    /// 알림 off 배너 표시 여부
    var isNotiOffShown: Bool = true

    /// 알림 권한 상태
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// 네트워크 에러 발생 여부
    var hasNetworkError: Bool = false

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var userManager = UserManager.shared
    private let notificationManager = NotificationManager.shared

    // MARK: - Firestore 알림 관리
    /// Firestore에서 알림 가져오기
    func fetchNotifications() {
        guard let userId = userManager.currentUser?.id else {
            print("사용자 ID를 찾을 수 없습니다")
            return
        }
        
        isLoadingNotifications = true

        db.collection("Notifications")
            .whereField("receiverId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50) // 최근 50개만 가져오기
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                self.isLoadingNotifications = false

                if let error = error {
                    print("알림 조회 실패: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("알림 문서가 없습니다")
                    self.notifications = []
                    self.isNotiEmpty = true
                    return
                }

                // Firestore 문서 → KeychyNotification 모델 변환
                self.notifications = documents.compactMap { document in
                    KeychyNotification(documentId: document.documentID, data: document.data())
                }

                // 빈 상태 업데이트
                self.isNotiEmpty = self.notifications.isEmpty

                print("알림 \(self.notifications.count)개 로드됨")
            }
    }

    /// 알림을 읽음 처리
    func markNotificationAsRead(_ notification: KeychyNotification) {
        guard let notificationId = notification.documentId else {
            print("알림 문서 ID가 없습니다")
            return
        }

        // 이미 읽음 상태면 스킵
        if notification.isRead {
            return
        }

        db.collection("Notifications")
            .document(notificationId)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("알림 읽음 처리 실패: \(error.localizedDescription)")
                } else {
                    print("알림 읽음 처리 완료: \(notificationId)")
                    Task { @MainActor in
                        UserManager.shared.updateBadgeCount()
                    }
                }
            }
    }

    /// 단일 알림 삭제 (Notifications + PostOffice)
    func deleteNotification(_ notification: KeychyNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        deleteNotification(at: IndexSet(integer: index))
    }

    /// 알림 삭제 (Notifications + PostOffice)
    func deleteNotification(at offsets: IndexSet) {
        for index in offsets {
            let notification = notifications[index]

            guard let notificationId = notification.documentId else { continue }

            // 1. Notifications 문서 삭제
            db.collection("Notifications")
                .document(notificationId)
                .delete { error in
                    if let error = error {
                        print("알림 삭제 실패: \(error.localizedDescription)")
                    } else {
                        print("알림 삭제 완료: \(notificationId)")
                    }
                }

            // 2. PostOffice 문서 삭제
            db.collection("PostOffice")
                .document(notification.postOfficeId)
                .delete { error in
                    if let error = error {
                        print("PostOffice 삭제 실패: \(error.localizedDescription)")
                    } else {
                        print("PostOffice 삭제 완료: \(notification.postOfficeId)")
                    }
                }
        }

        // 3. 로컬 배열에서 제거
        notifications.remove(atOffsets: offsets)

        // 4. 빈 상태 업데이트
        isNotiEmpty = notifications.isEmpty

        // 5. 뱃지 업데이트
        Task { @MainActor in
            UserManager.shared.updateBadgeCount()
        }
    }

    // MARK: - 알림 권한 관리

    /// 알림 권한 체크
    func checkNotificationPermission() {
        notificationManager.getAuthorizationStatus { [weak self] status in
            DispatchQueue.main.async { [weak self] in
                self?.authorizationStatus = status
                // authorized가 아니면 배너 표시 (notDetermined, denied 모두 포함)
                self?.isNotiOff = (status != .authorized)
            }
        }
    }

    /// 알림 배너 탭 처리
    func handleNotificationBannerTap() {
        if authorizationStatus == .notDetermined {
            // 아직 권한 요청 안한 경우 → 권한 요청 팝업 표시
            notificationManager.requestPermission { [weak self] granted in
                // 권한 요청 후 다시 체크
                self?.checkNotificationPermission()
            }
        } else {
            // 이미 거부된 경우 → 설정 앱으로 이동
            notificationManager.openSettings()
        }
    }
    
    /// 네트워크 에러 후 재시도
    func retryFetchNotifications() {
        guard NetworkManager.shared.isConnected else { return }
        hasNetworkError = false
        fetchNotifications()
    }

    // MARK: - 알림 키링 이미지 프리페치
    func prefetchNotificationImages() {
        Task(priority: .utility) {
            for notification in notifications {
                await prefetchSingleNotificationImage(postOfficeId: notification.postOfficeId)
            }
        }
    }
    
    private func prefetchSingleNotificationImage(postOfficeId: String) async {
        let db = Firestore.firestore()
        
        do {
            // PostOffice에서 키링 ID 가져오기
            let postOfficeDoc = try await db.collection("PostOffice")
                .document(postOfficeId)
                .getDocument()
            
            guard let data = postOfficeDoc.data(),
                  let keyringId = data["keyringId"] as? String else {
                print("PostOffice에서 키링 ID를 찾을 수 없음: \(postOfficeId)")
                return
            }
            
            // 이미 캐시가 있으면 스킵
            guard !KeyringImageCache.shared.exists(for: keyringId, type: .gift) else {
                return
            }
            
            // 키링 데이터 가져오기
            let keyringDoc = try await db.collection("Keyring")
                .document(keyringId)
                .getDocument()
            
            guard let keyringData = keyringDoc.data(),
                  let keyring = Keyring(documentId: keyringId, data: keyringData) else {
                print("키링 데이터를 불러올 수 없음: \(keyringId)")
                return
            }
            
            // 이미지 생성 및 캐시
            await prefetchKeyringImage(keyring: keyring)
            
        } catch {
            print("알림 이미지 프리페치 실패: \(error.localizedDescription)")
        }
    }
    
    private func prefetchKeyringImage(keyring: Keyring) async {
        guard let keyringID = keyring.documentId else { return }
        
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)

        await withCheckedContinuation { continuation in
            var loadingCompleted = false

            let scene = KeyringCellScene(
                ringType: ringType,
                chainType: chainType,
                bodyImage: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
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
                    continuation.resume()
                    return
                }

                try? await Task.sleep(for: .seconds(0.2))

                if let pngData = await scene.captureToPNG(),
                   !pngData.isEmpty,
                   UIImage(data: pngData) != nil {
                    KeyringImageCache.shared.save(pngData: pngData, for: keyringID, type: .gift)
                }

                continuation.resume()
            }
        }
    }
    

}
