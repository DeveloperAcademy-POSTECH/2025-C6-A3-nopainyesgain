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

    // 드래그 제스처용 (더 부드러운 추적)
    @GestureState private var dragOffset: CGSize = .zero

    // 콘텐츠 사이즈
    @State private var contentSize: CGSize = .zero
    @State private var viewSize: CGSize = .zero

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

    // 현재 총 오프셋
    private var totalOffset: CGSize {
        CGSize(
            width: offset.width + dragOffset.width,
            height: offset.height + dragOffset.height
        )
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear.onAppear {
                            contentSize = contentGeometry.size
                        }
                    }
                )
                .drawingGroup()
                .scaleEffect(currentZoom, anchor: .center)
                .offset(x: totalOffset.width, y: totalOffset.height)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(dragGesture(viewSize: geometry.size))
                .gesture(magnifyGesture(viewSize: geometry.size))
                .onAppear {
                    viewSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    viewSize = newSize
                }
        }
        .clipped()
        .onAppear {
            onZoomChange?(currentZoom)
        }
    }

    // MARK: - 드래그 제스처

    private func dragGesture(viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                offset = CGSize(
                    width: offset.width + value.translation.width,
                    height: offset.height + value.translation.height
                )
                constrainOffset(viewSize: viewSize)
            }
    }

    // MARK: - 핀치 줌 제스처

    private func magnifyGesture(viewSize: CGSize) -> some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                let newZoom = lastZoom * value.magnification
                currentZoom = min(max(newZoom, minZoom), maxZoom)
                onZoomChange?(currentZoom)
            }
            .onEnded { _ in
                lastZoom = currentZoom
                constrainOffset(viewSize: viewSize)
            }
    }

    // MARK: - 오프셋 제한

    private func constrainOffset(viewSize: CGSize) {
        let scaledWidth = contentSize.width * currentZoom
        let scaledHeight = contentSize.height * currentZoom

        let maxOffsetX = max(0, (scaledWidth - viewSize.width) / 2 + padding.leading)
        let maxOffsetY = max(0, (scaledHeight - viewSize.height) / 2 + padding.top)

        let constrainedX = min(max(offset.width, -maxOffsetX), maxOffsetX)
        let constrainedY = min(max(offset.height, -maxOffsetY), maxOffsetY)

        // 제한이 필요한 경우에만 애니메이션
        if offset.width != constrainedX || offset.height != constrainedY {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                offset = CGSize(width: constrainedX, height: constrainedY)
            }
        }

        lastOffset = offset
    }
}
