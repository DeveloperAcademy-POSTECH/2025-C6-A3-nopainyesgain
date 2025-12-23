//
//  CollectionKeyringDetailView+Helpers.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI

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
