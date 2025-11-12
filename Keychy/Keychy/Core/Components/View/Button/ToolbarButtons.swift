//
//  ToolbarButtons.swift
//  Keychy
//
//  Created by 길지훈 on 11/12/25.
//

import SwiftUI

/// 기본적으로 .toolbar에 들어갈 아이템입니다.
/// 커스텀 툴바를 구축하면 글래스를 따로 적용해야합니다.

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
