//
//  KeychyApp.swift
//  Keychy
//
//  Created by 길지훈 on 10/26/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
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

    // MARK: - APNs 토큰 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // FCM에 APNs 토큰 전달
        Messaging.messaging().apnsToken = deviceToken
    }

    // MARK: - APNs 토큰 등록 실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] 디바이스 토큰 등록 실패: \(error.localizedDescription)")
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // 폰트 설정
        let selectedFont = UIFont(name: "NanumSquareRoundOTFEB", size: 10) ?? UIFont.systemFont(ofSize: 10)
        let deselectedFont = UIFont(name: "NanumSquareRoundOTFB", size: 10) ?? UIFont.systemFont(ofSize: 10)
        
        
        let selectedAttributes: [NSAttributedString.Key: Any] = [.font: selectedFont]
        let deselectedAttributes: [NSAttributedString.Key: Any] = [.font: deselectedFont]
        
        

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = deselectedAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = deselectedAttributes
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = deselectedAttributes
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = selectedAttributes

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

@main
struct KeychyApp: App {
    // 파이어베이스 setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    print("onOpenURL 호출됨: \(url)")
                    handleDeepLink(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    print("onContinueUserActivity 호출됨")
                    print("   activityType: \(userActivity.activityType)")
                    print("   webpageURL: \(userActivity.webpageURL?.absoluteString ?? "nil")")
                    if let url = userActivity.webpageURL {
                        handleDeepLink(url)
                    }
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        print("   URL 수신: \(url)")
        print("   scheme: \(url.scheme ?? "nil")")
        print("   host: \(url.host ?? "nil")")
        print("   path: \(url.path)")
        
        // Universal Link 처리
        if url.scheme == "https" && url.host == "keychy-f6011.web.app" {
            handleUniversalLink(url)
            return
        }
        
        // Custom URL Scheme 처리
        if url.scheme == "keychy" {
            if url.host == "receive" {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let postOfficeId = components.queryItems?.first(where: { $0.name == "postOfficeId" })?.value else {
                    return
                }
                print("Custom URL Scheme - receive postOfficeId: \(postOfficeId)")
                DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .receive)
            } else if url.host == "collect" {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let postOfficeId = components.queryItems?.first(where: { $0.name == "postOfficeId" })?.value else {
                    return
                }
                print("Custom URL Scheme - collect postOfficeId: \(postOfficeId)")
                DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .collect)
            }
        }
    }
    
    // Universal Links (배포용)
    private func handleUniversalLink(_ url: URL) {
        print("Universal Link 수신: \(url)")
        
        guard url.host == "keychy-f6011.web.app" else { return }
        
        let path = url.path
        
        // https://keychy-f6011.web.app/receive/POSTOFFICE_ID
        if path.hasPrefix("/receive/") {
            let postOfficeId = String(path.dropFirst("/receive/".count))
            DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .receive)
        }
        // https://keychy-f6011.web.app/collect/POSTOFFICE_ID
        else if path.hasPrefix("/collect/") {
            let postOfficeId = String(path.dropFirst("/collect/".count))
            DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .collect)
        } else {
            print("경로 파싱 실패")
        }
    }
}

// MARK: - RootView
// WindowGroup에 바로 .onAppear를 못 붙이는 관계로 따로 빼서 Group으로 묶음
struct RootView: View {
    @State private var introViewModel = IntroViewModel()
    @State private var userManager = UserManager.shared
    @State private var purchaseManager = PurchaseManager.shared
    @State private var isCheckingAuth = true

    var body: some View {
        Group {
            if isCheckingAuth {
                SplashView()
                    .onAppear {
                        // 스플래시 표시하면서 유저 확인
                        checkAuthAndNavigate()
                    }
            } else {
                // 유저 상태에 따라 화면 전환
                if introViewModel.showAppGuiding {
                    // 앱 가이드 화면
                    IntroAppGuidingView(viewModel: introViewModel)
                } else if introViewModel.showProfileComplete {
                    // 프로필 완료 화면
                    ProfileSetupCompleteView(viewModel: introViewModel)
                } else if introViewModel.needsProfileSetup {
                    // 프로필 설정 필요
                    ProfileSetupView(viewModel: introViewModel)
                } else if introViewModel.isLoggedIn {
                    // 로그인 완료 → 메인 화면
                    MainTabView()
                        .environment(userManager)
                        .environment(introViewModel)
                } else {
                    // 로그인 필요 → 로그인 화면
                    IntroView(viewModel: introViewModel)
                }
            }
        }
        .background(.gray800)
    }
    
    private func checkAuthAndNavigate() {
        let minimumSplashTime: TimeInterval = 1.5 // 최소 1.5초 스플래시 표시
        let startTime = Date()

        // 첫 설치 여부 확인
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

        if let user = Auth.auth().currentUser, hasLaunchedBefore {
            // 기존 사용자 + 로그인 세션 있음 → 자동 로그인
            print("로그인된 사용자 발견 (자동 로그인): \(user.uid)")
            
            // Firebase에서 유저 프로필 확인
            UserManager.shared.loadUserInfo(uid: user.uid) { hasProfile in
                let elapsed = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, minimumSplashTime - elapsed)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                    if hasProfile {
                        // 프로필 있음 → 메인 화면
                        introViewModel.isLoggedIn = true
                        introViewModel.needsProfileSetup = false
                    } else {
                        // 프로필 없음 → 약관 동의부터 시작 (신규 가입 플로우)
                        introViewModel.tempUserUID = user.uid
                        introViewModel.tempUserEmail = user.email ?? ""
                        introViewModel.isLoggedIn = false
                        introViewModel.needsProfileSetup = false
                        introViewModel.showTermsSheet = true  // 약관 동의 시트 표시
                    }
                    isCheckingAuth = false
                }
            }
        } else {
            // 첫 설치 또는 로그인 세션 없음 → 로그인 화면
            if !hasLaunchedBefore {
                print("첫 설치: 로그인 화면으로 이동")
            } else {
                print("로그인 세션 없음: 로그인 화면으로 이동")
            }

            let elapsed = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, minimumSplashTime - elapsed)

            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                // 첫 실행 플래그 저장 (이후부턴 자동 로그인 가능)
                if !hasLaunchedBefore {
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }

                introViewModel.isLoggedIn = false
                introViewModel.needsProfileSetup = false
                isCheckingAuth = false
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate (포그라운드 알림)
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
            DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .collect)
        }

        completionHandler()
    }
}

// MARK: - MessagingDelegate (FCM 토큰)
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
