//
//  NotificationManager.swift
//  Keychy
//
//  Created by Claude on 11/9/25.
//

import SwiftUI
import UserNotifications

@Observable
class NotificationManager {
    static let shared = NotificationManager()

    /// 알림 권한 상태
    var isAuthorized: Bool = false

    private init() {
        // 초기화 시 권한 체크
        checkPermission { _ in }
    }

    // MARK: - 알림 권한 체크
    /// 현재 알림 권한 상태를 확인
    func checkPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                let authorized = settings.authorizationStatus == .authorized
                self?.isAuthorized = authorized
                completion(authorized)
            }
        }
    }

    // MARK: - 알림 권한 요청
    /// 알림 권한 요청 (처음 요청 시에만 시스템 팝업 표시)
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion(granted)
            }
        }
    }

    // MARK: - 설정 앱 열기
    /// iOS 설정 앱의 해당 앱 설정 화면으로 이동
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
