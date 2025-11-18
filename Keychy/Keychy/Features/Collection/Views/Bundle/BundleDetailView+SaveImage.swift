//
//  BundleDetailView+SaveImage.swift
//  Keychy
//
//  Created by seo on 11/15/25.
//
// 뭉치 이미지 저장하는 로직을 담은 화면입니다.
import SwiftUI
import Photos

extension BundleDetailView {
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
    @MainActor
    func saveImageToLibrary(_ image: UIImage) async {
        await withCheckedContinuation { continuation in
            requestPhotoLibraryPermission { [self] granted in
                guard granted else {
                    Task { @MainActor in
                        isCapturing = false
                    }
                    continuation.resume()
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    Task { @MainActor in
                        if success {
                            print("[BundleDetailView] 이미지 저장 성공")
                        } else if let error = error {
                            print("[BundleDetailView] 이미지 저장 실패: \(error.localizedDescription)")
                        }
                        
                        // 캡처 상태 해제
                        self.isCapturing = false
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    func captureAndSaveScene() async {
        guard let bundle = viewModel.selectedBundle else {
            return 
        }
        
        // 캡쳐 시작
        await MainActor.run {
            isCapturing = true
        }
        
        // 배경 및 카라비너 로드
        guard let cb = viewModel.resolveCarabiner(from: bundle.selectedCarabiner),
              let bg = WorkshopDataManager.shared.backgrounds.first(where: { $0.id == bundle.selectedBackground }) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }
        
        // 캡쳐용 키링 데이터 생성 - Firebase에서 키링 정보 가져오기
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []
        
        for (index, keyringId) in bundle.keyrings.enumerated() {
            // 유효하지 않은 키링 ID 필터링
            guard index < cb.maxKeyringCount,
                  keyringId != "none",
                  !keyringId.isEmpty else { 
                continue 
            }
            
            // Firebase에서 키링 정보 가져오기
            guard let keyringInfo = await viewModel.fetchKeyringInfo(keyringId: keyringId) else {
                continue
            }
            
            keyringDataList.append(
                MultiKeyringCaptureScene.KeyringData(
                    index: index,
                    position: CGPoint(
                        x: cb.keyringXPosition[index],
                        y: cb.keyringYPosition[index]
                    ),
                    bodyImageURL: keyringInfo.bodyImage,
                    hookOffsetY: keyringInfo.hookOffsetY
                )
            )
        }
        
        let carabinerType = CarabinerType.from(cb.carabinerType)
        let carabinerBackURL: String?
        let carabinerFrontURL: String?
        
        if carabinerType == .hamburger {
            carabinerBackURL = cb.carabinerImage[1]
            carabinerFrontURL = cb.carabinerImage[2]
        } else {
            //plain 타입일 때
            carabinerBackURL = cb.carabinerImage[0]
            carabinerFrontURL = nil
        }
        
        guard let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: bg.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerX: cb.carabinerX,
            carabinerY: cb.carabinerY,
            carabinerWidth: cb.carabinerWidth
        ) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }
        
        // viewModel에 캡쳐된 이미지 저장
        await MainActor.run {
            viewModel.bundleCapturedImage = pngData
        }
        
        if let documentId = bundle.documentId,
           !BundleImageCache.shared.exists(for: documentId) {
            BundleImageCache.shared.syncBundle(
                id: documentId,
                name: bundle.name,
                imageData: pngData
            )
            print("[BundleDetailView] 편집된 뭉치 캐시 복구: \(documentId)")
        }
        
        // PNG 데이터를 UIImage로 변환하여 포토 라이브러리에 저장
        guard let image = UIImage(data: pngData) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }
        
        await saveImageToLibrary(image)
    }
}
