//
//  AlarmViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/15/24.
//

import SwiftUI
import FirebaseFirestore
import UserNotifications

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
                        self.updateBadgeCount()
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
            updateBadgeCount()
        }
    }

    /// 앱 아이콘 뱃지를 읽지 않은 알림 개수로 업데이트
    func updateBadgeCount() {
        // 1. 먼저 뱃지를 0으로 초기화 (기존의 잘못된 숫자 제거)
        UNUserNotificationCenter.current().setBadgeCount(0)

        // 2. 읽지 않은 알림 개수를 다시 세서 설정
        let unreadCount = notifications.filter { !$0.isRead }.count
        UNUserNotificationCenter.current().setBadgeCount(unreadCount)

        print("뱃지 업데이트: \(unreadCount)")
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
}
