//
//  CollectionKeyringDetailView+SaveImage.swift
//  Keychy
//
//  이미지 캡처 및 저장 기능
//

import SwiftUI
import Photos

// MARK: - Image Capture
extension CollectionKeyringDetailView {
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
extension CollectionKeyringDetailView {
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
                    }
                }
            }
        }
    }

    /// 이미지 캡처 및 저장 (메인 함수)
    func captureAndSaveImage() {
        // 1. 시트 내리기 + UI opacity를 0으로 (서서히 사라짐)
        withAnimation(.easeOut(duration: 0.3)) {
            showUIForCapture = false
            isSheetPresented = false
        }

        // 2. 애니메이션 완료 대기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 3. 캡처 (UI 없는 깨끗한 화면)
            guard let image = self.captureVisibleScreen() else {
                // 실패 시 UI 복원
                withAnimation(.easeIn(duration: 0.3)) {
                    self.showUIForCapture = true
                    self.isSheetPresented = false
                }
                return
            }

            // 4. 이미지 저장
            self.saveImageToLibrary(image)

            // 5. UI 복원 (서서히 나타남)
            withAnimation(.easeIn(duration: 0.3)) {
                self.showUIForCapture = true
                self.isSheetPresented = false
            }
        }
    }
}
