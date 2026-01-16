//
//  PullToRefreshIndicator.swift
//  Keychy
//
//  Created by 길지훈 on 1/5/26.
//
//  Pull to Refresh 인디케이터 UI 컴포넌트
//

import SwiftUI

struct PullToRefreshIndicator: View {
    let opacity: Double
    let isRefreshing: Bool

    var body: some View {
        AnimatedGIFView(
            source: .local("pullToRefresh"),
            size: CGSize(width: 100, height: 30),
            opacity: isRefreshing ? 1.0 : opacity
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        PullToRefreshIndicator(opacity: 0.5, isRefreshing: false)
        PullToRefreshIndicator(opacity: 1.0, isRefreshing: true)
    }
}
