//
//  KeychyApp.swift
//  Keychy
//
//  Created by 길지훈 on 10/26/25.
//

import SwiftUI

@main
struct KeychyApp: App {
    // 파이어베이스 setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    DeepLinkHandler.shared.handle(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        DeepLinkHandler.shared.handle(url)
                    }
                }
        }
    }
}
