//
//  PackageCompleteView+SaveImage.swift
//  Keychy
//
//  Created by Jini on 11/11/25.
//

import SwiftUI
import Photos

extension PackageCompleteView {
    
    // MARK: - 현재 페이지만 캡처
    @MainActor
    func captureCurrentPage() -> UIImage? {
        // 현재 페이지에 따라 적절한 뷰 선택
        let targetView: AnyView = currentPage == 0
            ? AnyView(captureablePackagePreviewPage)
            : AnyView(captureableKeyringOnlyPage)
        
        // 화면 크기 가져오기
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        let screenSize = windowScene.screen.bounds.size
        
        // 배경 포함한 전체 뷰 구성
        let captureView = ZStack {
            Image("GreenBackground")
                .resizable()
                .scaledToFill()
                .frame(width: screenSize.width, height: screenSize.height)
            
            targetView
                .frame(width: 240)
        }
        
        // UIHostingController로 렌더링
        let controller = UIHostingController(rootView: captureView)
        controller.view.bounds = CGRect(origin: .zero, size: screenSize)
        controller.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: screenSize)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    // MARK: - 이미지 확대 및 크롭
    func enlargeImage(_ image: UIImage, scale: CGFloat = 1.15) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let originalSize = image.size
        
        // 크롭할 영역 계산 (중앙에서 scale만큼 작게)
        let cropWidth = originalSize.width / scale
        let cropHeight = originalSize.height / scale
        
        let cropX = (originalSize.width - cropWidth) / 2
        let cropY = (originalSize.height - cropHeight) / 2
        
        // CGImage 좌표계에 맞게 변환 (scale 고려)
        let imageScale = image.scale
        let cropRect = CGRect(
            x: cropX * imageScale,
            y: cropY * imageScale,
            width: cropWidth * imageScale,
            height: cropHeight * imageScale
        )
        
        // 크롭
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return nil
        }
        
        // 원본 크기로 다시 렌더링 (확대 효과)
        let renderer = UIGraphicsImageRenderer(size: originalSize)
        return renderer.image { _ in
            let drawRect = CGRect(origin: .zero, size: originalSize)
            UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: image.imageOrientation)
                .draw(in: drawRect)
        }
    }
    
    // MARK: - 캡처용 페이지 (UI 요소 제외)
    var captureablePackagePreviewPage: some View {
        VStack(spacing: 0) {
            packageImageStack
        }
        .padding(.horizontal, 20)
    }
    
    var captureableKeyringOnlyPage: some View {
        VStack(spacing: 0) {
            qrCodeImageStack
        }
        .frame(width: 240, height: 390)
        .padding(.horizontal, 20)
    }
    
    // MARK: - 포토 라이브러리 권한 요청
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
    
    // MARK: - 이미지 저장
    func saveImageToLibrary(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        requestPhotoLibraryPermission { granted in
            guard granted else {
                completion(false)
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }
    
    // MARK: - 메인 저장 함수
    func captureAndSaveCurrentPage(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            guard let capturedImage = self.captureCurrentPage() else {
                completion(false)
                return
            }
            
            // 이미지 확대 (scale: 1.15 = 약 15% 확대)
            guard let enlargedImage = self.enlargeImage(capturedImage, scale: 1.15) else {
                completion(false)
                return
            }
            
            self.saveImageToLibrary(enlargedImage) { success in
                if success {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.showImageSaved = true
                    }
                } else {
                    print("이미지 저장 실패")
                }
                completion(success)
            }
        }
    }
}
