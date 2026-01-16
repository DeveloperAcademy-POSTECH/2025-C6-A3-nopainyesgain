//
//  KeyringVideoGenerator+Sound.swift
//  Keychy
//
//  Created by 길지훈 on 1/13/26.
//

import Foundation
import AVFoundation
import CoreMedia
import SpriteKit

// MARK: - Sound Effects

extension KeyringVideoGenerator {

    /// 특정 프레임에서 사운드 이벤트 기록
    /// - 0.5초(30 프레임): 스와이프 임팩트 시 사운드
    func triggerSoundEvents(at frameIndex: Int, scene: KeyringScene) {
        if frameIndex == swipeEventFrame {
            let velocity = CGVector(dx: swipeVelocity, dy: 0)
            scene.applySwipeForceToNearbyChains(
                at: CGPoint(
                    x: scene.size.width / 2,
                    y: scene.size.height / 2
                ),
                velocity: velocity
            )

            if scene.currentSoundId != "none" {
                soundEvents.append(SoundEvent(
                    time: 0.5,
                    soundId: scene.currentSoundId
                ))
            }
        }
    }

    /// 비디오에 사운드 트랙 추가
    /// soundEvents 배열 기반으로 사운드 파일을 비디오에 합성
    func addSoundToVideo(videoURL: URL) async throws -> URL {
        // 사운드 이벤트 없으면 원본 반환
        guard !soundEvents.isEmpty else {
            return videoURL
        }

        let composition = AVMutableComposition()

        // 비디오 트랙 추가
        let videoAsset = AVURLAsset(url: videoURL)
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first else {
            return videoURL
        }

        let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        let videoDuration = try await videoAsset.load(.duration)
        try compositionVideoTrack?.insertTimeRange(
            CMTimeRange(start: .zero, duration: videoDuration),
            of: videoTrack,
            at: .zero
        )

        // 오디오 트랙 추가
        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        // 각 사운드 이벤트를 오디오 트랙에 삽입
        for event in soundEvents {
            guard let soundURL = findSoundURL(soundId: event.soundId) else {
                continue
            }

            let audioAsset = AVURLAsset(url: soundURL)
            guard let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first else {
                continue
            }

            let audioDuration = try await audioAsset.load(.duration)
            let startTime = CMTime(seconds: event.time, preferredTimescale: 600)

            try compositionAudioTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration),
                of: audioTrack,
                at: startTime
            )
        }

        // 최종 비디오 Export
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("keyring_video_with_audio_\(UUID()).mp4")

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw VideoError.saveFailed
        }

        try await exportSession.export(to: outputURL, as: .mp4)

        // 원본 비디오 파일 삭제
        try? FileManager.default.removeItem(at: videoURL)

        return outputURL
    }

    /// 사운드 파일 URL 찾기
    /// 1. Firebase 캐시 확인 (sounds/soundId.mp3)
    /// 2. 커스텀 녹음 파일인 경우 URL 직접 반환
    private func findSoundURL(soundId: String) -> URL? {
        // 커스텀 녹음 파일 (URL 형식)
        if soundId.starts(with: "file://") || soundId.starts(with: "/") {
            return URL(fileURLWithPath: soundId.replacingOccurrences(of: "file://", with: ""))
        }

        // Firebase 캐시
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("sounds/\(soundId).mp3")

        guard FileManager.default.fileExists(atPath: cachedURL.path) else {
            return nil
        }

        return cachedURL
    }
}
