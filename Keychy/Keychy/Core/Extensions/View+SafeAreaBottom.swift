//
//  View+SafeAreaBottom.swift
//  Keychy
//
//  Created by 길지훈 on 11/16/25.
//

import SwiftUI

extension View {
    /// 직각형 기기(SE2, 3? 더 있나)에서만 하단 패딩 추가
    /// 둥근 모서리 기기는 iOS가 자동으로 패딩 적용해서 추가안함.
    func adaptiveBottomPadding(_ defaultPadding: CGFloat = 34) -> some View {
        self.padding(.bottom, getBottomPadding(defaultPadding))
    }

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
}
