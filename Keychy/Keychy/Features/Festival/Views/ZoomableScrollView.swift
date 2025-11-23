//
//  ZoomableScrollView.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import SwiftUI

/// 순수 SwiftUI 기반의 확대/축소 가능한 스크롤뷰
struct ZoomableScrollView<Content: View>: View {
    let content: Content
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let initialZoom: CGFloat
    let onZoomChange: ((CGFloat) -> Void)?

    // 줌 상태
    @State private var currentZoom: CGFloat
    @State private var lastZoom: CGFloat

    // 오프셋 상태
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // 콘텐츠 사이즈
    @State private var contentSize: CGSize = .zero

    // 패딩
    private let padding = EdgeInsets(top: 50, leading: 30, bottom: 30, trailing: 30)

    init(
        minZoom: CGFloat = 1.0,
        maxZoom: CGFloat = 3.0,
        initialZoom: CGFloat = 1.0,
        onZoomChange: ((CGFloat) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.initialZoom = initialZoom
        self.onZoomChange = onZoomChange
        self._currentZoom = State(initialValue: initialZoom)
        self._lastZoom = State(initialValue: initialZoom)
    }

    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size

            content
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear.onAppear {
                            contentSize = contentGeometry.size
                        }
                    }
                )
                .scaleEffect(currentZoom)
                .offset(x: offset.width, y: offset.height)
                .frame(width: viewSize.width, height: viewSize.height)
                .contentShape(Rectangle())
                .gesture(
                    // 핀치 줌 제스처
                    MagnifyGesture()
                        .onChanged { value in
                            let newZoom = lastZoom * value.magnification
                            currentZoom = min(max(newZoom, minZoom), maxZoom)
                            onZoomChange?(currentZoom)
                        }
                        .onEnded { _ in
                            lastZoom = currentZoom
                            // 줌 후 오프셋 보정
                            constrainOffset(viewSize: viewSize)
                        }
                        .simultaneously(with:
                            // 드래그 제스처
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    constrainOffset(viewSize: viewSize)
                                    lastOffset = offset
                                }
                        )
                )
        }
        .clipped()
        .onAppear {
            onZoomChange?(currentZoom)
        }
    }

    // MARK: - 오프셋 제한

    private func constrainOffset(viewSize: CGSize) {
        let scaledWidth = contentSize.width * currentZoom
        let scaledHeight = contentSize.height * currentZoom

        // 스크롤 가능한 최대 범위 계산
        let maxOffsetX = max(0, (scaledWidth - viewSize.width) / 2 + padding.leading)
        let maxOffsetY = max(0, (scaledHeight - viewSize.height) / 2 + padding.top)

        withAnimation(.easeOut(duration: 0.2)) {
            offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
            offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
            lastOffset = offset
        }
    }
}
