//
//  View+PullToRefresh.swift
//  Keychy
//
//  Created by 길지훈 on 1/5/26.
//
//  Pull to Refresh Modifier
//

import SwiftUI

struct PullToRefreshModifier: ViewModifier {
    let topPadding: CGFloat
    let onRefresh: () async -> Void

    // 스크롤 위치 추적
    @State private var initialOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    @State private var hasSetInitialOffset: Bool = false

    // 제스처 & Refresh 상태
    @State private var isDragging: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var shouldHoldIndicator: Bool = false

    // 시각적 상태
    @State private var indicatorOpacity: Double = 0
    @State private var lastHapticDistance: CGFloat = 0

    // 상수 값
    private let threshold: CGFloat = 100        // Refresh가 트리거되는 최소 pull 거리
    private let hapticInterval: CGFloat = 4     // 햅틱 피드백 간격 (px)

    /// Pull 거리 계산
    private var pullDistance: CGFloat {
        max(currentOffset - initialOffset, 0)
    }

    // MARK: - Body
    func body(content: Content) -> some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .top) {
                scrollContent(content)
                indicator
            }
        }
        .simultaneousGesture(dragGesture)
    }

    // MARK: - Subviews
    /// 스크롤 콘텐츠 (offset reader + spacer + content)
    private func scrollContent(_ content: Content) -> some View {
        VStack(spacing: 0) {
            scrollOffsetReader
            contentSpacer
            content
        }
    }

    /// 스크롤 offset 추적용 GeometryReader
    private var scrollOffsetReader: some View {
        GeometryReader { geo in
            Color.clear
                .onChange(of: geo.frame(in: .global).minY) { old, new in
                    handleScrollOffsetChange(old: old, new: new)
                }
        }
        .frame(height: 1)
    }

    /// Refresh 중 content를 밀어내는 Spacer
    private var contentSpacer: some View {
        Spacer()
            .frame(height: shouldHoldIndicator ? 60 : min(pullDistance * 0.3, 60))
    }

    /// Pull to Refresh Indicator
    private var indicator: some View {
        PullToRefreshIndicator(
            opacity: indicatorOpacity,
            isRefreshing: isRefreshing
        )
        .allowsHitTesting(false)
        .padding(.top, shouldHoldIndicator ? topPadding + 50 : topPadding)
    }

    /// 드래그 제스처
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { _ in
                if !isDragging {
                    isDragging = true
                    lastHapticDistance = 0
                }
            }
            .onEnded { _ in
                isDragging = false
                lastHapticDistance = 0

                if pullDistance > threshold && !isRefreshing {
                    withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
                        shouldHoldIndicator = true
                        indicatorOpacity = 1
                    }
                    triggerRefresh()
                }
            }
    }

    // MARK: - Private Methods
    /// 스크롤 offset 변경 처리
    private func handleScrollOffsetChange(old: CGFloat, new: CGFloat) {
        // 초기 offset 설정
        if !hasSetInitialOffset {
            initialOffset = new
            currentOffset = new
            hasSetInitialOffset = true
            return
        }

        currentOffset = new
        let distance = max(currentOffset - initialOffset, 0)
        let isPullingDown = new > old

        // Pull 중 indicator opacity 업데이트
        if !isRefreshing && !shouldHoldIndicator {
            indicatorOpacity = min(distance / (threshold * 1.5), 1.0)
        }

        // 연속 햅틱 피드백 (4px 간격)
        if isPullingDown && distance > 0 && !isRefreshing {
            if distance > lastHapticDistance + hapticInterval {
                let style: UIImpactFeedbackGenerator.FeedbackStyle = distance < 95 ? .soft : .light
                Haptic.impact(style: style)
                lastHapticDistance = distance
            }
        }
    }

    /// Refresh 트리거
    private func triggerRefresh() {
        guard !isRefreshing else { return }

        isRefreshing = true
        shouldHoldIndicator = true

        Haptic.impact(style: .medium)

        Task {
            await onRefresh()
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
                    isRefreshing = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
                        shouldHoldIndicator = false
                        indicatorOpacity = 0
                    }
                }
            }
        }
    }
}

extension View {
    func pullToRefresh(
        topPadding: CGFloat = 0,
        onRefresh: @escaping () async -> Void
    ) -> some View {
        modifier(PullToRefreshModifier(topPadding: topPadding, onRefresh: onRefresh))
    }
}
