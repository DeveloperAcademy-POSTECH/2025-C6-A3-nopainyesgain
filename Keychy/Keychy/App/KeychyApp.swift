//
//  KeychyApp.swift
//  Keychy
//
//  Created by 길지훈 on 10/26/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // TabBar 외형 설정
        configureTabBarAppearance()
        
        return true
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
        }
    }
}

// MARK: - RootView
// WindowGroup에 바로 .onAppear를 못 붙이는 관계로 따로 빼서 Group으로 묶음
struct RootView: View {
    @State private var introViewModel = IntroViewModel()
    @State private var userManager = UserManager.shared
    
    var body: some View {
        Group {
            if introViewModel.needsProfileSetup {
                ProfileSetupView(viewModel: introViewModel)
            } else if introViewModel.isLoggedIn {
                MainTabView()
                    .environment(userManager)
            } else {
                IntroView(viewModel: introViewModel)
            }
        }
        .onAppear {
            // RootView onAppear시 Auth 확인 (Firebase 초기화된 상태)
            introViewModel.checkAuthStatus()
        }
    }
}
