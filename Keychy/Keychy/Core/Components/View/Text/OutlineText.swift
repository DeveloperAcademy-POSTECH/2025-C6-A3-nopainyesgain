//
//  OutlineText.swift
//  Keychy
//
//  Created by 길지훈 on 11/15/25.
//

import SwiftUI

/// 테두리가 있는 텍스트 컴포넌트
struct OutlineText: View {
    let text: String
    let outlineColor: Color
    let outlineWidth: CGFloat

    var body: some View {
        ZStack {
            // 테두리 효과 (16방향 - 더 매끄러움)
            ForEach(0..<16) { index in
                Text(text)
                    .foregroundStyle(outlineColor)
                    .offset(x: offset(for: index).width, y: offset(for: index).height)
            }

            // 메인 텍스트 (가장 위)
            Text(text)
        }
    }

    /// 16방향 offset 계산
    private func offset(for index: Int) -> CGSize {
        let angle = Double(index) * 22.5 * .pi / 180.0  // 360도 / 16방향 = 22.5도
        let x = cos(angle) * outlineWidth
        let y = sin(angle) * outlineWidth
        return CGSize(width: x, height: y)
    }
}

// MARK: - View Extension
extension View {
    /// 텍스트에 테두리를 추가합니다
    /// - Parameters:
    ///   - color: 테두리 색상
    ///   - width: 테두리 두께 (기본값: 1)
    func textOutline(color: Color, width: CGFloat = 1) -> some View {
        modifier(TextOutlineModifier(outlineColor: color, outlineWidth: width))
    }
}

// MARK: - ViewModifier
private struct TextOutlineModifier: ViewModifier {
    let outlineColor: Color
    let outlineWidth: CGFloat

    func body(content: Content) -> some View {
        ZStack {
            // 테두리 효과 (16방향 - 더 매끄러움)
            ForEach(0..<16) { index in
                content
                    .foregroundStyle(outlineColor)
                    .offset(x: offset(for: index).width, y: offset(for: index).height)
            }

            // 메인 텍스트 (가장 위)
            content
        }
    }

    /// 16방향 offset 계산
    private func offset(for index: Int) -> CGSize {
        // 360도 / 16방향 = 22.5도
        let angle = Double(index) * 22.5 * .pi / 180.0
        let x = cos(angle) * outlineWidth
        let y = sin(angle) * outlineWidth
        return CGSize(width: x, height: y)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        // 컴포넌트 사용
        OutlineText(
            text: "테두리 텍스트",
            outlineColor: .white,
            outlineWidth: 3
        )
        .typography(.suit17B)
        .foregroundStyle(.black100)
    }
    .padding()
    .background(.gray200)
}
