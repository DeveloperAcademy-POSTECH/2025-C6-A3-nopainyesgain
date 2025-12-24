//
//  CinematicAppearanceModifier.swift
//  Keychy
//
//  시네마틱한 등장 애니메이션을 제공하는 ViewModifier
//  - 페이드 인 + 슬라이드 업 + 스케일 효과
//

import SwiftUI

/// 시네마틱한 등장 애니메이션 스타일
enum CinematicStyle {
    case fadeIn          // 페이드 인만
    case slideUp         // 아래에서 위로 슬라이드
    case scaleUp         // 스케일 업
    case full            // 페이드 + 슬라이드 + 스케일
}

/// 시네마틱 등장 애니메이션 ViewModifier
struct CinematicAppearance: ViewModifier {
    let delay: Double
    let duration: Double
    let style: CinematicStyle

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: offsetY)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    isVisible = true
                }
            }
    }

    private var offsetY: CGFloat {
        guard !isVisible else { return 0 }

        switch style {
        case .slideUp, .full:
            return 50
        default:
            return 0
        }
    }

    private var scale: CGFloat {
        guard !isVisible else { return 1.0 }

        switch style {
        case .scaleUp, .full:
            return 0.8
        default:
            return 1.0
        }
    }
}

/// View Extension으로 편리하게 사용
extension View {
    /// 시네마틱한 등장 애니메이션 적용
    /// - Parameters:
    ///   - delay: 애니메이션 시작 지연 시간 (초)
    ///   - duration: 애니메이션 지속 시간 (초)
    ///   - style: 애니메이션 스타일
    func cinematicAppear(
        delay: Double = 0,
        duration: Double = 0.8,
        style: CinematicStyle = .full
    ) -> some View {
        modifier(CinematicAppearance(
            delay: delay,
            duration: duration,
            style: style
        ))
    }
}
