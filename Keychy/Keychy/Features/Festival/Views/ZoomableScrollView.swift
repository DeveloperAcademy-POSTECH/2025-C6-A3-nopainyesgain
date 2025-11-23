//
//  ZoomableScrollView.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import SwiftUI
import UIKit

/// UIScrollView 기반의 확대/축소 가능한 스크롤뷰
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let initialZoom: CGFloat

    init(
        minZoom: CGFloat = 1.0,
        maxZoom: CGFloat = 3.0,
        initialZoom: CGFloat = 1.0,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.initialZoom = initialZoom
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

        // 가로세로 30씩 패딩
        scrollView.contentInset = UIEdgeInsets(top: 50, left: 30, bottom: 30, right: 30)

        // 핀치 줌 즉시 반응하도록 설정
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true

        // SwiftUI 콘텐츠를 호스팅
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.backgroundColor = .clear
        hostedView.isMultipleTouchEnabled = true
        hostedView.frame = CGRect(origin: .zero, size: context.coordinator.hostingController.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)))

        scrollView.addSubview(hostedView)
        scrollView.contentSize = hostedView.frame.size

        // 핀치 제스처가 다른 제스처보다 우선하도록 설정
        if let pinchGesture = scrollView.pinchGestureRecognizer {
            pinchGesture.delaysTouchesBegan = false
            pinchGesture.delaysTouchesEnded = false
        }

        // 초기 줌 설정
        DispatchQueue.main.async {
            scrollView.setZoomScale(initialZoom, animated: false)
            // 중앙으로 스크롤
            let centerOffsetX = (scrollView.contentSize.width * initialZoom - scrollView.bounds.width) / 2
            let centerOffsetY = (scrollView.contentSize.height * initialZoom - scrollView.bounds.height) / 2
            scrollView.setContentOffset(CGPoint(x: max(0, centerOffsetX), y: max(0, centerOffsetY)), animated: false)
        }

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content

        let newSize = context.coordinator.hostingController.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        context.coordinator.hostingController.view.frame.size = newSize
        uiView.contentSize = newSize
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(hostingController: UIHostingController(rootView: content))
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController: UIHostingController<Content>

        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}
