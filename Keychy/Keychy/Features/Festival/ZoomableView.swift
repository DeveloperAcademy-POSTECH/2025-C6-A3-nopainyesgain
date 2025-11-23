//
//  ZoomableView.swift
//  Keychy
//
//  Created by seo on 11/23/25.
//

import UIKit
import SwiftUI

struct ZoomableView<Content: View>: UIViewRepresentable {
    let content: Content
    let minZoomScale: CGFloat
    let maxZoomScale: CGFloat
    
    init(
        // 여기서 최소 축소 스케일 최대 확장 스케일 정할 수 있어용
        minZoomScale: CGFloat = 0.5,
        maxZoomScale: CGFloat = 3.0,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.minZoomScale = minZoomScale
        self.maxZoomScale = maxZoomScale
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minZoomScale
        scrollView.maximumZoomScale = maxZoomScale
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.clipsToBounds = true
        
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        
        scrollView.addSubview(hostingController.view)
        
        // 더블탭 제스처 메서드입니다
        let doubleTapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        // 두번 탭하면 되어요
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        context.coordinator.hostingController = hostingController
        context.coordinator.scrollView = scrollView
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        
        DispatchQueue.main.async {
            if let hostingView = context.coordinator.hostingController?.view {
                let contentSize = hostingView.intrinsicContentSize
                hostingView.frame.size = contentSize
                scrollView.contentSize = contentSize
                
                if !context.coordinator.hasSetInitialZoom {
                    context.coordinator.hasSetInitialZoom = true
                    context.coordinator.setInitialZoom()
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        var scrollView: UIScrollView?
        var hasSetInitialZoom = false
        var initialZoomScale: CGFloat = 1.0
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController?.view
        }
        
        func setInitialZoom() {
            guard let scrollView = scrollView,
                  let hostingView = hostingController?.view else { return }
            
            let contentSize = hostingView.frame.size
            let scrollViewSize = scrollView.bounds.size
            
            let scaleWidth = scrollViewSize.width / contentSize.width
            let scaleHeight = scrollViewSize.height / contentSize.height
            let minScale = min(scaleWidth, scaleHeight)
            
            scrollView.minimumZoomScale = minScale
            scrollView.zoomScale = minScale
            initialZoomScale = minScale
            
            centerContent()
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            
            if scrollView.zoomScale > initialZoomScale {
                // 두 번 탭 하면 원래대로 돌아가거나
                scrollView.setZoomScale(initialZoomScale, animated: true)
            } else {
                // 확대 시킵니다
                let tapPoint = gesture.location(in: scrollView)
                let zoomScale = min(scrollView.maximumZoomScale, initialZoomScale * 2.5)
                
                let width = scrollView.bounds.width / zoomScale
                let height = scrollView.bounds.height / zoomScale
                let x = tapPoint.x - (width / 2)
                let y = tapPoint.y - (height / 2)
                
                let zoomRect = CGRect(x: x, y: y, width: width, height: height)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent()
        }
        
        private func centerContent() {
            guard let scrollView = scrollView,
                  let hostingView = hostingController?.view else { return }
            
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            
            hostingView.center = CGPoint(
                x: scrollView.contentSize.width * 0.5 + offsetX,
                y: scrollView.contentSize.height * 0.5 + offsetY
            )
        }
    }
}
