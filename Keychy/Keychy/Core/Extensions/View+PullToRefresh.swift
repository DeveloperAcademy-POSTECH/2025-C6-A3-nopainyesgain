//
//  View+PullToRefresh.swift
//  Keychy
//
//  Created by 길지훈 on 1/5/26.
//
//  Pull to Refresh Modifier
//

import SwiftUI

// MARK: - Scroll Offset PreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PullToRefreshModifier: ViewModifier {
    let onRefresh: () async -> Void

    @State private var initialOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    @State private var maxDistanceDuringDrag: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var hasSetInitialOffset: Bool = false
    @State private var hasReachedThreshold: Bool = false
    private let threshold: CGFloat = 80

    private var pullDistance: CGFloat {
        max(currentOffset - initialOffset, 0)  // Only positive distances
    }

    func body(content: Content) -> some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let minY = geo.frame(in: .global).minY
                        Color.clear
                            .onChange(of: minY) { old, new in
                                if !hasSetInitialOffset {
                                    initialOffset = new
                                    currentOffset = new
                                    hasSetInitialOffset = true
                                    return
                                }

                                currentOffset = new
                                let distance = max(currentOffset - initialOffset, 0)
                                let isPullingDown = new > old

                                // 드래그 중일 때만 maxDistance 업데이트
                                if isDragging {
                                    maxDistanceDuringDrag = max(maxDistanceDuringDrag, distance)
                                }

                                // Threshold를 처음 넘는 순간 햅틱 (pull down 중일 때만)
                                if distance > threshold && !hasReachedThreshold && !isRefreshing && isPullingDown {
                                    hasReachedThreshold = true
                                    Haptic.impact(style: .light)
                                } else if distance <= threshold {
                                    hasReachedThreshold = false
                                }
                            }

                    }
                    .frame(height: 1)

                    content
                }

                // Indicator를 content와 같은 ZStack에 배치
                PullToRefreshIndicator(
                    opacity: calculateOpacity(),
                    isRefreshing: isRefreshing
                )
                .padding(.top, 20)
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    if !isDragging {
                        isDragging = true
                        maxDistanceDuringDrag = 0
                        hasReachedThreshold = false
                    }
                }
                .onEnded { _ in
                    isDragging = false

                    // 딱 손 뗐을 때만 refresh
                    if maxDistanceDuringDrag > threshold && !isRefreshing {
                        triggerRefresh()
                    }

                    // 상태 정리
                    maxDistanceDuringDrag = 0
                    hasReachedThreshold = false
                }
        )

    }

    private func calculateOpacity() -> Double {
        guard pullDistance > 0 else { return 0 }
        return min(pullDistance / threshold, 1.0)
    }

    private func triggerRefresh() {
        isRefreshing = true
        Haptic.impact(style: .medium)

        Task {
            await onRefresh()
            await MainActor.run {
                isRefreshing = false
                currentOffset = initialOffset
            }
        }
    }
}

extension View {
    func pullToRefresh(onRefresh: @escaping () async -> Void) -> some View {
        modifier(PullToRefreshModifier(onRefresh: onRefresh))
    }
}
