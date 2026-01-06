//
//  Haptic.swift
//  Keychy
//
//  Created by 길지훈 on 10/27/25.
//

import SwiftUI

final class Haptic {
    // 각 스타일별 제너레이터 캐싱
    private static var generators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]

    // 앱 시작 시 호출하여 제너레이터 준비
    static func prepare() {
        // 자주 사용하는 스타일들 미리 준비
        _ = getGenerator(for: .soft)
        _ = getGenerator(for: .light)
        _ = getGenerator(for: .medium)
        _ = getGenerator(for: .rigid)
    }

    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = getGenerator(for: style)
        generator.impactOccurred()
        generator.prepare()
    }

    private static func getGenerator(for style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        if let generator = generators[style] {
            return generator
        }

        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generators[style] = generator
        return generator
    }
}
