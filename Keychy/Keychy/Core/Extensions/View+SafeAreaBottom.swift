//
//  View+SafeAreaBottom.swift
//  Keychy
//
//  Created by 길지훈 on 11/16/25.
//

import SwiftUI

extension View {
    // 직각형 기기(SE2, 3? 더 있나)에서만 패딩 추가합니다.

    /// 하단
    func adaptiveBottomPadding(_ defaultPadding: CGFloat = 34) -> some View {
        self.padding(.bottom, getBottomPadding(defaultPadding))
    }

    /// 상단
    func adaptiveTopPadding(_ defaultPadding: CGFloat = 20) -> some View {
        self.padding(.top, getTopPadding(defaultPadding))
    }

    /// 하단 safeArea 값 반환
    private func getBottomPadding(_ defaultPadding: CGFloat) -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return defaultPadding
        }
        
        // safeAreaInsets.bottom이 0이면 직각형 기기임!
        return window.safeAreaInsets.bottom == 0 ? defaultPadding : 0
    }
    /// 상단 safeArea 값 반환
    private func getTopPadding(_ defaultPadding: CGFloat) -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return defaultPadding
        }

        return window.safeAreaInsets.top == 0 ? defaultPadding : 0
    }
}
