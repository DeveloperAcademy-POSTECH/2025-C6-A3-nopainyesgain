//
//  CustomNavigationBar.swift
//  Keychy
//
//  Created by 길지훈 on 11/16/25.
//

import SwiftUI

struct CustomNavigationBar<Leading: View, Center: View, Trailing: View>: View {
    let leading: Leading
    let center: Center
    let trailing: Trailing

    init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder center: () -> Center,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                leading
                    .frame(width: 44, height: 44)
                    .padding(.leading, 16)

                Spacer()

                center

                Spacer()

                trailing
                    .frame(minWidth: 44, minHeight: 44)
                    .padding(.trailing, 16)
            }
            .frame(height: 44)
            .padding(.top, getSafeAreaTop())

            Spacer()
        }
    }

    /// 기기별 safeArea 계산
    /// 다이나믹아일랜드, 노치 이런거 크기를 계산할 수 있는 방법
    private func getSafeAreaTop() -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return 0
        }
        return window.safeAreaInsets.top
    }
}

// MARK: - 편의 생성자 (Center만 사용)
extension CustomNavigationBar where Leading == EmptyView, Trailing == EmptyView {
    init(@ViewBuilder center: () -> Center) {
        self.leading = EmptyView()
        self.center = center()
        self.trailing = EmptyView()
    }
}

// MARK: - 편의 생성자 (Leading + Center)
extension CustomNavigationBar where Trailing == EmptyView {
    init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder center: () -> Center
    ) {
        self.leading = leading()
        self.center = center()
        self.trailing = EmptyView()
    }
}
