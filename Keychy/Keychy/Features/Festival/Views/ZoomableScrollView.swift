//
//  ZoomableScrollView.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import SwiftUI
import UIKit

/// UIKit 기반의 확대/축소 가능한 스크롤뷰
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let initialZoom: CGFloat
    let onZoomChange: ((CGFloat) -> Void)?

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
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minZoom
        scrollView.maximumZoomScale = maxZoom
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear

        // SwiftUI 콘텐츠를 호스팅
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hostingController.view)
        context.coordinator.hostingController = hostingController

        // 콘텐츠 크기 설정
        DispatchQueue.main.async {
            let size = hostingController.view.intrinsicContentSize
            hostingController.view.frame = CGRect(origin: .zero, size: size)
            scrollView.contentSize = size

            // 초기 줌 설정
            scrollView.zoomScale = initialZoom
            self.centerContent(scrollView: scrollView)
            self.onZoomChange?(initialZoom)
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // 콘텐츠 업데이트 (스크롤 중이 아닐 때만)
        guard !context.coordinator.isZooming && !context.coordinator.isDragging else { return }

        context.coordinator.hostingController?.rootView = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func centerContent(scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width * scrollView.zoomScale) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height * scrollView.zoomScale) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        var hostingController: UIHostingController<Content>?
        var isZooming = false
        var isDragging = false

        init(_ parent: ZoomableScrollView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // 줌 중 콘텐츠 중앙 정렬
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width * scrollView.zoomScale) / 2, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height * scrollView.zoomScale) / 2, 0)
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)

            parent.onZoomChange?(scrollView.zoomScale)
        }

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            isZooming = true
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            isZooming = false
            parent.onZoomChange?(scale)
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isDragging = true
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isDragging = false
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isDragging = false
        }
    }
}
