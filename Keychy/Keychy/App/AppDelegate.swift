//
//  AppDelegate.swift
//  Keychy
//
//  Created on 12/23/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

/// UIKit AppDelegate를 SwiftUI 앱에 통합
/// - Firebase 초기화 (FirebaseApp.configure)
/// - 푸시 알림 설정 (APNs 토큰 등록, FCM 연동)
/// - TabBar 커스텀 폰트 설정 (NanumSquareRound)
/// - 포그라운드 알림 처리 및 딥링크 라우팅
class AppDelegate: NSObject, UIApplicationDelegate {
    // MARK: - Lifecycle

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Firebase 초기화
        FirebaseApp.configure()

        // TabBar 외형 설정
        configureTabBarAppearance()

        // 푸시 알림 설정
        setupPushNotifications(application)

        return true
    }

    // MARK: - 푸시 알림 설정
    private func setupPushNotifications(_ application: UIApplication) {
        // UNUserNotificationCenter delegate 설정
        UNUserNotificationCenter.current().delegate = self

        // Messaging delegate 설정
        Messaging.messaging().delegate = self

        // 푸시 알림 등록 (APNs 토큰 받기)
        application.registerForRemoteNotifications()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // FCM에 APNs 토큰 전달
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] 디바이스 토큰 등록 실패: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // 앱이 포그라운드에 있을 때 알림 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 배너, 소리, 뱃지 모두 표시
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 탭했을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // postOfficeId 추출해서 화면 이동
        if let postOfficeId = userInfo["postOfficeId"] as? String {
            DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .notification)
        }

        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    // FCM 토큰 받았을 때
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }

        // 현재 로그인한 사용자 ID 가져오기
        if let userId = Auth.auth().currentUser?.uid {
            NotificationManager.shared.updateFCMToken(fcmToken, userId: userId)
        }
    }
}
