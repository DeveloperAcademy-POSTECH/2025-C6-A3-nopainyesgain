//
//  TabBarManager.swift
//  Keychy
//
//  Created by 길지훈 on 1/13/26.
//

import SwiftUI
import UIKit

/// 탭바 표시/숨김 전역 관리
enum TabBarManager {
    /// 탭바 숨기기
    static func hide() {
        guard let tabBarController = findTabBarController() else { return }
        tabBarController.tabBar.isHidden = true
    }

    /// 탭바 보이기
    static func show() {
        guard let tabBarController = findTabBarController() else { return }
        tabBarController.tabBar.isHidden = false
    }

    /// TabBarController 찾기
    private static func findTabBarController() -> UITabBarController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }

        return rootViewController.findTabBarController()
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    /// UITabBarController 재귀 탐색
    func findTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }

        for child in children {
            if let tabBarController = child.findTabBarController() {
                return tabBarController
            }
        }

        return parent?.findTabBarController()
    }
}
