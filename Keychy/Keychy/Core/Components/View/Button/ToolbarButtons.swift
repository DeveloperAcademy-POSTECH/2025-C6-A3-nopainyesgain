//
//  ToolbarButtons.swift
//  Keychy
//
//  Created by 길지훈 on 11/12/25.
//

import SwiftUI

// MARK: - Back Toolbar Button
struct BackToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("BackIcon")
        }
    }
}

// MARK: - Next Toolbar Button
struct NextToolbarButton: View {
    let title: String
    let action: () -> Void

    init(
        title: String = "다음",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .typography(.suit17B)
                .foregroundStyle(.gray600)
        }
    }
}

// MARK: - Close Toolbar Button (X 버튼)
struct CloseToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("dismiss")
        }
    }
}

// MARK: - Custom Text Toolbar Button
struct TextToolbarButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .typography(.suit17M)
                .foregroundStyle(.black100)
        }
    }
}
