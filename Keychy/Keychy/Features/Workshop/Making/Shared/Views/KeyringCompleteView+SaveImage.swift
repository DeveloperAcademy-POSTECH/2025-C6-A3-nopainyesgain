//
//  KeyringCompleteView+SaveImage.swift
//  Keychy
//
//  이미지 캡처 및 저장 기능
//

import SwiftUI
import Photos

// MARK: - Image Capture
extension KeyringCompleteView {
    /// 현재 화면을 직접 캡처 (window hierarchy 사용)
    @MainActor
    func captureVisibleScreen() -> UIImage? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Photo Library Save
extension KeyringCompleteView {
    /// 포토 라이브러리 권한 요청
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    /// 이미지를 포토 라이브러리에 저장
    func saveImageToLibrary(_ image: UIImage) {
        requestPhotoLibraryPermission { granted in
            guard granted else {
                // TODO: 권한 거부 시 설정 유도 alert
                print("Photo library permission denied")
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { [self] success, error in
                DispatchQueue.main.async {
                    if success {
                        // 저장 성공 애니메이션
                        showImageSaved = true
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                            checkmarkScale = 1.0
                            checkmarkOpacity = 1.0

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                                    checkmarkScale = 0.0
                                    checkmarkOpacity = 0.0
                                    showImageSaved = false
                                }
                            }
                        }
                    } else if let error = error {
                        print("Error saving image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// 이미지 캡처 및 저장 (메인 함수)
    func captureAndSaveImage() {
        // 1. 저장 버튼과 toolbar 임시 숨기기 (애니메이션 없이)
        let originalShowDismissButton = showDismissButton

        withAnimation(.none) {
            showDismissButton = false
            showSaveButton = false
        }

        // 2. UI 업데이트 완전히 대기 후 캡처 (0.5초로 증가)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let image = self.captureVisibleScreen() else {
                print("Failed to capture image")
                // UI 복원 (애니메이션 없이)
                withAnimation(.none) {
                    self.showDismissButton = originalShowDismissButton
                    self.showSaveButton = true
                }
                return
            }

            // 3. 이미지 저장
            self.saveImageToLibrary(image)

            // 4. UI 복원 (애니메이션 없이)
            withAnimation(.none) {
                self.showDismissButton = originalShowDismissButton
                self.showSaveButton = true
            }
        }
    }
}
