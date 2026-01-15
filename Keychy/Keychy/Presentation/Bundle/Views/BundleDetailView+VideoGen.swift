//
//  BundleDetailView+VideoGen.swift
//  Keychy
//
//  Created by Claude Code on 1/14/26.
//

import SwiftUI
import Photos

// MARK: - Video Generation

extension BundleDetailView {

    /// 영상 생성 및 사진 앨범에 저장
    @MainActor
    func generateAndSaveVideo() async {
        uiState.isGeneratingVideo = true

        do {
            // 영상 생성에 필요한 데이터 준비
            guard let bundle = bundleVM.selectedBundle,
                  let carabiner = bundleVM.resolveCarabiner(from: bundle.selectedCarabiner),
                  let background = bundleVM.selectedBackground else {
                uiState.isGeneratingVideo = false
                return
            }

            // 배경 이미지 로드
            let backgroundImage = await loadImage(from: background.backgroundImage)

            // 영상 생성
            let videoURL = try await videoGenerator.generateVideo(
                keyringDataList: keyringDataList,
                backgroundImage: backgroundImage,
                backgroundImageURL: background.backgroundImage,
                carabinerBackImageURL: carabiner.backImageURL,
                carabinerFrontImageURL: carabiner.frontImageURL,
                carabinerX: carabiner.carabinerX,
                carabinerY: carabiner.carabinerY,
                carabinerWidth: carabiner.carabinerWidth,
                carabinerType: carabiner.type,
                bundleScale: 2.5
            )

            // 사진 앨범 저장
            try await saveVideoToPhotoLibrary(url: videoURL)

            // 성공 Alert 표시
            await MainActor.run {
                uiState.showVideoSaved = true
            }

            // 임시 파일 삭제
            try? FileManager.default.removeItem(at: videoURL)

        } catch {
            print("[BundleDetailView] 영상 생성 실패: \(error)")
            print("[BundleDetailView] Error localizedDescription: \(error.localizedDescription)")
            if let videoError = error as? BundleVideoGenerator.VideoError {
                print("[BundleDetailView] VideoError: \(videoError)")
            }
        }

        uiState.isGeneratingVideo = false
    }

    /// 비디오 파일을 사진 라이브러리에 저장
    private func saveVideoToPhotoLibrary(url: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }

    /// URL에서 이미지 로드
    private func loadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("[BundleDetailView] 배경 이미지 로드 실패: \(error)")
            return nil
        }
    }
}
