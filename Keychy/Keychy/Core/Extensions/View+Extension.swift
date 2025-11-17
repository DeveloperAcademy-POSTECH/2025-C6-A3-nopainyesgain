//
//  View+Extension.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import UIKit
import SwiftUI

extension View {
    /// 아무 곳 터치 시, 키보드 창 내립니다.
    func dismissKeyboardOnTap() -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture {
            #if canImport(UIKit)
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            #endif
            }
    }
    
    /// 키보드 창이 내려가는 메서드 입니다.
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - SwipeBack 관리

/// 네비게이션 스와이프 제스처를 제어하는 Helper
struct SwipeBackHelper: UIViewControllerRepresentable {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            // 현재 뷰컨트롤러에서 네비게이션 컨트롤러 찾기
            if let navigationController = uiViewController.navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = isEnabled
                navigationController.interactivePopGestureRecognizer?.delegate = isEnabled ? nil : context.coordinator
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }
    }
}

// MARK: - View Extension for SwipeBack
extension View {
    /// 네비게이션 스와이프 백 제스처 활성화/비활성화
    /// - Parameter enabled: true면 스와이프 백 활성화, false면 비활성화
    func swipeBackGesture(enabled: Bool) -> some View {
        self.background(SwipeBackHelper(isEnabled: enabled))
    }
}
