//
//  Haptic.swift
//  Keychy
//
//  Created by 길지훈 on 10/27/25.
//

import SwiftUI

final class Haptic {
    // 재사용을 위한 제너레이터 (static으로 미리 생성)
    private static let impactGenerator = UIImpactFeedbackGenerator(style: .medium)

    // 앱 시작 시 호출하여 제너레이터 준비
    static func prepare() {
        impactGenerator.prepare()
    }

    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        impactGenerator.impactOccurred()
        // 사용 후 다시 prepare() 호출 - 다음 햅틱 지연 최소화
        impactGenerator.prepare()
    }
}
