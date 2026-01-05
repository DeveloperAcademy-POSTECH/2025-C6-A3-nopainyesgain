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
    let onRefresh: () async -> Void

    @State private var initialOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var hasSetInitialOffset: Bool = false
    @State private var hasReachedThreshold: Bool = false
    @State private var shouldHoldIndicator: Bool = false
    @State private var holdHeight: CGFloat = 0
    @State private var lastHapticDistance: CGFloat = 0

    private let holdTarget: CGFloat = 80
    private let threshold: CGFloat = 100
    private let hapticInterval: CGFloat = 4
    
    private var pullDistance: CGFloat {
        max(currentOffset - initialOffset, 0)
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

                                // 연속 햅틱 (4px 간격)
                                if isPullingDown && distance > 0 && !isRefreshing {
                                    if distance > lastHapticDistance + hapticInterval {
                                        
                                        // 거의 끝까지 .soft로 가볍게, 마지막에만 .light
                                        let style: UIImpactFeedbackGenerator.FeedbackStyle
                                        if distance < 95 {
                                            style = .soft
                                        } else {
                                            style = .light
                                        }

                                        Haptic.impact(style: style)
                                        lastHapticDistance = distance
                                    }
                                }

                                if distance > threshold && !hasReachedThreshold {
                                    hasReachedThreshold = true
                                } else if distance <= threshold {
                                    hasReachedThreshold = false
                                }
                            }

                    }
                    .frame(height: 1)

                    Spacer()
                        .frame(height: holdHeight)
                    
                    content
                }
                
                // Indicator를 content와 같은 ZStack에 배치
                PullToRefreshIndicator(
                    opacity: calculateOpacity(),
                    isRefreshing: isRefreshing
                )
                .offset(y: holdHeight)
                .allowsHitTesting(false)
                .padding(.top, 40)
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    if !isDragging {
                        isDragging = true
                        lastHapticDistance = 0
                        hasReachedThreshold = false
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    
                    // 드래그 종료 시 리셋
                    lastHapticDistance = 0

                    if pullDistance > threshold && !isRefreshing {
                        shouldHoldIndicator = true
                        triggerRefresh()
                    }

                    hasReachedThreshold = false
                }
        )
    }
    
    private func calculateOpacity() -> Double {
        if isRefreshing || shouldHoldIndicator { return 1 }
        guard pullDistance > 0 else { return 0 }
        return min(pullDistance / threshold, 1.0)
    }

    private func triggerRefresh() {
        guard !isRefreshing else { return }

        isRefreshing = true
        shouldHoldIndicator = true

        Haptic.impact(style: .medium)

        withAnimation(.spring(response: 0.6, dampingFraction: 1.0)) {
            holdHeight = holdTarget
        }
        
        Task {
            await onRefresh()
            await MainActor.run {

                withAnimation(.spring(response: 0.7, dampingFraction: 1.0)) {
                    holdHeight = 0
                    isRefreshing = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    shouldHoldIndicator = false
                }
            }
        }
    }
}

extension View {
    func pullToRefresh(onRefresh: @escaping () async -> Void) -> some View {
        modifier(PullToRefreshModifier(onRefresh: onRefresh))
    }
}
