//
//  ToastManager.swift
//  Keychy
//
//  Created on 12/26/24.
//

import SwiftUI

// MARK: - Toast Position
enum ToastPosition {
    case `default`  // 하단에 아무것도 없음
    case tabbar     // 탭바 존재
    case button     // 버튼 존재

    var additionalPadding: CGFloat {
        switch self {
        case .default: return 50
        case .tabbar: return 20
        case .button: return 20
        }
    }
}

/// 전역 토스트 알림 관리자
@Observable
final class ToastManager {
    static let shared = ToastManager()

    /// 토스트 표시 여부
    var showToast = false

    /// 토스트 투명도
    var opacity: Double = 0

    /// 외부 생성 방지 (싱글톤)
    private init() {}

    /// 토스트 표시 (3초 후 자동 숨김)
    func show() {
        opacity = 0
        showToast = true

        Task { @MainActor in
            // SwiftUI는 동기적으로 상태 변화를 감지 못할 때가 있어서, sleep으로 타이밍 제어!
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeInOut(duration: 0.3)) { opacity = 1 }

            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeInOut(duration: 0.3)) { opacity = 0 }

            try? await Task.sleep(for: .seconds(0.3))
            showToast = false
        }
    }
}

// MARK: - Toast View Modifier
struct ToastModifier: ViewModifier {
    @Bindable var toastManager = ToastManager.shared
    let bottomPadding: CGFloat

    func body(content: Content) -> some View {
        ZStack {
            content

            // 토스트 오버레이
            if toastManager.showToast {
                VStack {
                    Spacer()

                    NoInternetToast()
                        .padding(.bottom, bottomPadding)
                        .opacity(toastManager.opacity)
                }
            }
        }
    }
}

// MARK: - View Extension for Network Toast
extension View {
    /// 토스트 알림 기능 추가
    /// - Parameter position: 토스트 위치 (default: .default)
    func withToast(position: ToastPosition = .default) -> some View {
        modifier(ToastModifier(bottomPadding: position.additionalPadding))
    }
}
