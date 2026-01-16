//
//  KeychyApp.swift
//  Keychy
//
//  Created by 길지훈 on 10/26/25.
//

import SwiftUI

/// Keychy 앱의 진입점
/// - AppDelegate를 통해 Firebase, Push 알림 등의 초기 설정 수행
/// - DeepLinkHandler를 통해 Custom URL Scheme 및 Universal Link 처리
@main
struct KeychyApp: App {
    // MARK: - Properties
    /// AppDelegate 연결: Firebase 초기화, 푸시 알림 설정, TabBar 스타일 설정 등을 처리
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // 네트워크 모니터링 시작
        NetworkManager.shared.startMonitoring()
    }
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            RootView()
                // 다크모드 미지원 - 추후 디자인시스템 추가될 예정
                .preferredColorScheme(.light)
            
                // Universal Link
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        DeepLinkHandler.shared.handle(url)
                    }
                }
        
                // Custom URL Scheme
                .onOpenURL { url in
                    DeepLinkHandler.shared.handle(url)
                }
        }
    }
}
