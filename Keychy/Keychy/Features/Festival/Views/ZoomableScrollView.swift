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
    let contentPadding: UIEdgeInsets
    let onZoomChange: ((CGFloat) -> Void)?

    init(
        minZoom: CGFloat = 1.0,
        maxZoom: CGFloat = 3.0,
        initialZoom: CGFloat = 1.0,
        contentPadding: UIEdgeInsets = UIEdgeInsets(top: 120, left: 50, bottom: 60, right: 50),
        onZoomChange: ((CGFloat) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.initialZoom = initialZoom
        self.contentPadding = contentPadding
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
        scrollView.contentInsetAdjustmentBehavior = .never

        // SwiftUI 콘텐츠를 호스팅
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hostingController.view)
        context.coordinator.hostingController = hostingController
        context.coordinator.contentPadding = contentPadding

        // 콘텐츠 크기 설정
        DispatchQueue.main.async {
            let size = hostingController.view.intrinsicContentSize
            hostingController.view.frame = CGRect(origin: .zero, size: size)
            scrollView.contentSize = size

            // 초기 줌 설정
            scrollView.zoomScale = initialZoom
            context.coordinator.updateContentInset(scrollView: scrollView)
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

    // MARK: - Coordinator

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        var hostingController: UIHostingController<Content>?
        var contentPadding: UIEdgeInsets = .zero
        var isZooming = false
        var isDragging = false

        init(_ parent: ZoomableScrollView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            updateContentInset(scrollView: scrollView)
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

        func updateContentInset(scrollView: UIScrollView) {
            // 고정 패딩 적용
            scrollView.contentInset = contentPadding
        }
    }
}
