//
//  EffectManager.swift
//  Keychy
//
//  Created by Rundo on 11/3/25.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore
import AVFoundation

/// 이펙트(사운드, 파티클) 다운로드 및 재생을 관리하는 매니저
@MainActor
@Observable
class EffectManager {
    static let shared = EffectManager()

    var downloadProgress: [String: Double] = [:]
    var downloadingItemIds: Set<String> = []
    var playingParticleId: String?

    private init() {}

    // MARK: - Ownership Check

    /// 사운드 소유 여부 확인
    func isOwned(soundId: String, userManager: UserManager) -> Bool {
        guard let user = userManager.currentUser else { return false }
        return user.soundEffects.contains(soundId)
    }

    /// 파티클 소유 여부 확인
    func isOwned(particleId: String, userManager: UserManager) -> Bool {
        guard let user = userManager.currentUser else { return false }
        return user.particleEffects.contains(particleId)
    }

    /// 사운드가 Bundle에 포함되어 있는지
    func isInBundle(soundId: String) -> Bool {
        return Bundle.main.url(forResource: soundId, withExtension: "mp3") != nil
    }

    /// 파티클이 Bundle에 포함되어 있는지
    func isInBundle(particleId: String) -> Bool {
        return Bundle.main.url(forResource: particleId, withExtension: "json") != nil
    }

    /// 사운드가 Cache에 다운로드되어 있는지
    func isInCache(soundId: String) -> Bool {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("sounds/\(soundId).mp3")
        return FileManager.default.fileExists(atPath: cachedURL.path)
    }

    /// 파티클이 Cache에 다운로드되어 있는지
    func isInCache(particleId: String) -> Bool {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")
        return FileManager.default.fileExists(atPath: cachedURL.path)
    }

    // MARK: - Download

    /// 사운드 다운로드
    func downloadSound(_ sound: Sound, userManager: UserManager) async {
        guard let soundId = sound.id else { return }

        // 이미 다운로드 중이면 무시
        guard !downloadingItemIds.contains(soundId) else { return }

        // 다운로드 시작
        downloadingItemIds.insert(soundId)
        downloadProgress[soundId] = 0.0

        // Firebase Storage에서 다운로드
        let storageRef = Storage.storage().reference(forURL: sound.soundData)

        // 로컬 캐시 경로
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let localURL = cacheDirectory.appendingPathComponent("sounds/\(soundId).mp3")

        // sounds 디렉토리 생성
        try? FileManager.default.createDirectory(at: cacheDirectory.appendingPathComponent("sounds"), withIntermediateDirectories: true)

        // 다운로드 진행
        let downloadTask = storageRef.write(toFile: localURL)

        // 진행률 관찰
        _ = downloadTask.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            guard progress.totalUnitCount > 0 else { return }

            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            // NaN, Infinite 체크
            guard percentComplete.isFinite else { return }

            Task { @MainActor in
                self?.downloadProgress[soundId] = percentComplete
            }
        }

        // 다운로드 완료 대기
        await withCheckedContinuation { continuation in
            downloadTask.observe(.success) { _ in
                continuation.resume()
            }
            downloadTask.observe(.failure) { _ in
                continuation.resume()
            }
        }

        // 파일 쓰기 완료 확인 (짧은 대기)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        // 파일 존재 확인
        var attempts = 0
        while !FileManager.default.fileExists(atPath: localURL.path) && attempts < 5 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            attempts += 1
        }

        // 사운드 프리로드 (재생 준비)
        await SoundEffectComponent.shared.preloadSound(named: soundId)

        // 다운로드 상태 초기화
        downloadingItemIds.remove(soundId)
        downloadProgress.removeValue(forKey: soundId)
    }

    /// 파티클 다운로드
    func downloadParticle(_ particle: Particle, userManager: UserManager) async {
        guard let particleId = particle.id else { return }

        // 이미 다운로드 중이면 무시
        guard !downloadingItemIds.contains(particleId) else { return }

        // 다운로드 시작
        downloadingItemIds.insert(particleId)
        downloadProgress[particleId] = 0.0

        // Firebase Storage에서 다운로드
        let storageRef = Storage.storage().reference(forURL: particle.particleData)

        // 로컬 캐시 경로
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let localURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

        // particles 디렉토리 생성
        try? FileManager.default.createDirectory(at: cacheDirectory.appendingPathComponent("particles"), withIntermediateDirectories: true)

        // 다운로드 진행
        let downloadTask = storageRef.write(toFile: localURL)

        // 진행률 관찰
        _ = downloadTask.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            guard progress.totalUnitCount > 0 else { return }

            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

            // NaN, Infinite 체크
            guard percentComplete.isFinite else { return }

            Task { @MainActor in
                self?.downloadProgress[particleId] = percentComplete
            }
        }

        // 다운로드 완료 대기
        await withCheckedContinuation { continuation in
            downloadTask.observe(.success) { _ in
                continuation.resume()
            }
            downloadTask.observe(.failure) { _ in
                continuation.resume()
            }
        }

        // 파일 쓰기 완료 확인 (짧은 대기)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        // 파일 존재 확인
        var attempts = 0
        while !FileManager.default.fileExists(atPath: localURL.path) && attempts < 5 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            attempts += 1
        }

        // 다운로드 상태 초기화
        downloadingItemIds.remove(particleId)
        downloadProgress.removeValue(forKey: particleId)
    }

    // MARK: - Play

    /// 사운드 재생 (다운로드 후 자동 재생)
    func playSound(_ sound: Sound, userManager: UserManager) async {
        guard let soundId = sound.id else { return }

        // 이미 캐시 또는 Bundle에 있으면 바로 재생
        if isInCache(soundId: soundId) || isInBundle(soundId: soundId) {
            SoundEffectComponent.shared.playSound(named: soundId)
            return
        }

        // 다운로드 필요
        await downloadSound(sound, userManager: userManager)

        // 다운로드 완료 후 재생
        SoundEffectComponent.shared.playSound(named: soundId)
    }

    /// 파티클 재생 (다운로드 후 자동 재생)
    func playParticle(_ particle: Particle, userManager: UserManager) async {
        guard let particleId = particle.id else { return }

        // 이미 캐시 또는 Bundle에 있으면 바로 재생
        if isInCache(particleId: particleId) || isInBundle(particleId: particleId) {
            playingParticleId = particleId
            return
        }

        // 다운로드 필요
        await downloadParticle(particle, userManager: userManager)

        // 다운로드 완료 후 재생
        playingParticleId = particleId
    }

    /// 파티클 파일 URL 찾기 (캐시 → Bundle 순서)
    func findParticleURL(particleId: String) -> URL? {
        // 1. 로컬 캐시에서 찾기
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

        if FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }

        // 2. Bundle에서 찾기 (기본 무료 파티클)
        if let bundleURL = Bundle.main.url(forResource: particleId, withExtension: "json") {
            return bundleURL
        }

        return nil
    }

    // MARK: - Private

    /// 아이템 타입
    private enum ItemType {
        case sound
        case particle

        var firestoreField: String {
            switch self {
            case .sound: return "soundEffects"
            case .particle: return "particleEffects"
            }
        }
    }

    /// UserManager의 유저 데이터 새로고침
    private func refreshUserData(userManager: UserManager) async {
        guard let userId = userManager.currentUser?.id else { return }

        await withCheckedContinuation { continuation in
            userManager.loadUserInfo(uid: userId) { _ in
                continuation.resume()
            }
        }
    }
}
