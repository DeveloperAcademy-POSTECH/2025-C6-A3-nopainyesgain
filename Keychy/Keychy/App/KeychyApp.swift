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

    return true
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
