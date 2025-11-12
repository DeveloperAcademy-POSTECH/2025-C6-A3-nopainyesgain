//
//  KeyringInfoInputView+Helpers.swift
//  Keychy
//
//  Helper components for KeyringInfoInputView
//

import SwiftUI

// MARK: - Computed Properties
extension KeyringInfoInputView {
    /// 시트가 펼쳐진 상태인지 확인
    var isSheetExpanded: Bool {
        sheetDetent != .height(76)
    }

    /// 씬 스케일 (시트 최대화 시 작게, 최소화 시 크게)
    var sceneScale: CGFloat {
        isSheetExpanded ? 0.7 : 1.2
    }

    /// 씬 Y 오프셋 (시트 최대화 시 위로 이동)
    var sceneYOffset: CGFloat {
        isSheetExpanded ? -120 : 0
    }
}

// MARK: - KeyringScene Section
extension KeyringInfoInputView {
    var keyringScene: some View {
        KeyringSceneView(viewModel: viewModel)
            .frame(maxWidth: .infinity)
            .scaleEffect(sceneScale)
            .offset(y: sceneYOffset)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: sheetDetent)
            .allowsHitTesting(!isSheetExpanded)
    }
}

// MARK: - Toolbar
extension KeyringInfoInputView {
    var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !showAddTagAlert {
                BackToolbarButton {
                    showSheet = false
                    viewModel.resetInfoData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        router.pop()
                    }
                }
            }
        }
    }

    var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !showAddTagAlert {
                NextToolbarButton(title: "완료") {
                    dismissKeyboard()
                    showSheet = false
                    router.push(nextRoute)
                    showAddTagAlert = false
                    showTagNameAlreadyExistsToast = false
                    showTagNameEmptyToast = false
                    viewModel.createdAt = Date()
                }
                .disabled(viewModel.nameText.isEmpty)
            }
        }
    }
}

// MARK: - KeyboardResponder
@Observable
final class KeyboardResponder {
    private var notificationCenter: NotificationCenter
    private(set) var currentHeight: CGFloat = 0

    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
    }

    @objc func keyBoardWillHide(notification: Notification) {
        currentHeight = 0
    }
}
