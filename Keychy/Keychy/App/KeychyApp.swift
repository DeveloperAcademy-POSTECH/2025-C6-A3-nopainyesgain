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
      //@StateObject var viewModel = MKViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
