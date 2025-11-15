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
    func captureAndSaveScene() async {
        guard let bundle = viewModel.selectedBundle else { return }
        
        // 캡쳐 시작
        await MainActor.run {
            isCapturing = true
        }
        
        // 배경 이미지 로드
        guard let cb = viewModel.resolveCarabiner(from: bundle.selectedCarabiner), let bg = WorkshopDataManager.shared.backgrounds.first(where: { $0.id == bundle.selectedBackground }) else { return }
        
        // 캡쳐용 키링 데이터 생성 (ID를 실제 Keyring 객체로 변환)
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []
        for (index, keyringId) in bundle.keyrings.enumerated() {
            if let keyring = viewModel.resolveKeyring(from: keyringId) {
                keyringDataList.append(
                    MultiKeyringCaptureScene.KeyringData(
                        index: index,
                        position: CGPoint(
                            x: cb.keyringXPosition[index],
                            y: cb.keyringYPosition[index]
                            ),
                        bodyImageURL: keyring.bodyImage
                    )
                )
            }
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
        
        if let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: bg.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerX: cb.carabinerX,
            carabinerY: cb.carabinerY,
            carabinerWidth: cb.carabinerWidth,
        ) {
            await MainActor.run {
                viewModel.bundleCapturedImage = pngData
            }
        } else {
            print("[BundleDetailView : 캡쳐 실패")
        }
        
        await MainActor.run {
            isCapturing = false
        }
    }
}
