//
//  CollectionKeyringDetailView+VideoGen.swift
//  Keychy
//
//  Created by 길지훈 on 1/15/26.
//

import SwiftUI
import Photos

extension CollectionKeyringDetailView {
    /// 영상 생성 및 저장
    func generateAndSaveVideo() async {
        guard !isGeneratingVideo else { return }

        await MainActor.run {
            isGeneratingVideo = true
        }

        do {
            // 영상 생성
            let videoURL = try await videoGenerator.generateVideo(keyring: keyring)

            // 포토 라이브러리에 저장
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }

            // 임시 파일 삭제
            try? FileManager.default.removeItem(at: videoURL)

            // 완료 처리
            await MainActor.run {
                isGeneratingVideo = false
                showVideoSaved = true
            }

        } catch {
            print("[CollectionKeyringDetailView] 영상 생성 실패: \(error)")
            await MainActor.run {
                isGeneratingVideo = false
            }
        }
    }
}
