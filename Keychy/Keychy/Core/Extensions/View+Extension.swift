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

    /// 네비게이션 스와이프 제스처를 활성화합니다.
    /// `.navigationBarBackButtonHidden(true)` 사용 시에도 스와이프로 뒤로가기가 가능하도록 합니다.
    func enableSwipeBack() -> some View {
        self.background(SwipeBackHelper())
    }
}

/// 네비게이션 스와이프 제스처를 활성화하는 Helper
struct SwipeBackHelper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let navigationController = uiViewController.navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = true
                navigationController.interactivePopGestureRecognizer?.delegate = nil
            }
        }
    }
}
