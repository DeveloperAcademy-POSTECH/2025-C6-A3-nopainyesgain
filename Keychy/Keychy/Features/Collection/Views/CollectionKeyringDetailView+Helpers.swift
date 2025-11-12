//
//  CollectionKeyringDetailView+Helpers.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI

// MARK: - Helper Extensions
extension UIViewController {
    // UITabBarController 찾기 헬퍼 익스텐션
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

// MARK: - PreferenceKey
struct MenuButtonPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct TextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
