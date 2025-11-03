//
//  AcrylicPhotoVM+Effect.swift
//  KeytschPrototype
//
//  Created by rundo on 10/22/25.
//

import Combine
import FirebaseFirestore
import FirebaseStorage

extension AcrylicPhotoVM {

    /// 커스터마이징 모드 (아크릴 포토는 이펙트만 지원)
    var availableCustomizingModes: [CustomizingMode] {
        [.effect]
    }

    /// 사운드 업데이트
    func updateSound(_ sound: Sound?) {
        selectedSound = sound
        soundId = sound?.id ?? "none"
        effectSubject.send((soundId, particleId, .sound))
    }

    /// 파티클 업데이트
    func updateParticle(_ particle: Particle?) {
        selectedParticle = particle
        particleId = particle?.id ?? "none"
        effectSubject.send((soundId, particleId, .particle))
    }

    // MARK: - Custom Sound (녹음)

    /// 커스텀 사운드 존재 여부
    var hasCustomSound: Bool {
        customSoundURL != nil
    }

    /// 커스텀 사운드 적용
    func applyCustomSound(_ url: URL) {
        customSoundURL = url

        // 기존 사운드 선택 해제
        selectedSound = nil

        // soundId를 특별한 값으로 설정 (나중에 재생 시 구분)
        soundId = "custom_recording"
        effectSubject.send((soundId, particleId, .sound))
    }

    /// 커스텀 사운드 제거
    func removeCustomSound() {
        customSoundURL = nil
        soundId = "none"
        effectSubject.send((soundId, particleId, .sound))
    }

    // MARK: - Ownership Check

    /// 사운드 소유 여부 확인 (Firebase 구매 기록)
    func isOwned(soundId: String) -> Bool {
        guard let user = userManager.currentUser else { return false }
        return user.soundEffects.contains(soundId)
    }

    /// 파티클 소유 여부 확인 (Firebase 구매 기록)
    func isOwned(particleId: String) -> Bool {
        guard let user = userManager.currentUser else { return false }
        return user.particleEffects.contains(particleId)
    }

    /// 사운드가 Bundle에 포함되어 있는지 (앱에 포함된 무료 아이템)
    func isInBundle(soundId: String) -> Bool {
        return Bundle.main.url(forResource: soundId, withExtension: "mp3") != nil
    }

    /// 파티클이 Bundle에 포함되어 있는지 (앱에 포함된 무료 아이템)
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
    func downloadSound(_ sound: Sound) async {
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

        // 다운로드 완료 후 자동 선택
        await MainActor.run {
            updateSound(sound)
        }

        // 무료 아이템이면 Firestore에 소유권 추가 (백그라운드 처리)
        if sound.isFree {
            Task {
                guard let userId = userManager.currentUser?.id else { return }

                try? await Firestore.firestore()
                    .collection("User")
                    .document(userId)
                    .updateData([
                        "soundEffects": FieldValue.arrayUnion([soundId])
                    ])

                // UserManager 업데이트
                await refreshUserData()
            }
        }

        // 다운로드 상태 초기화
        downloadingItemIds.remove(soundId)
        downloadProgress.removeValue(forKey: soundId)
    }

    /// 파티클 다운로드
    func downloadParticle(_ particle: Particle) async {
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

        // 다운로드 완료 후 자동 선택
        await MainActor.run {
            updateParticle(particle)
        }

        // 무료 아이템이면 Firestore에 소유권 추가 (백그라운드 처리)
        if particle.isFree {
            Task {
                guard let userId = userManager.currentUser?.id else { return }

                try? await Firestore.firestore()
                    .collection("User")
                    .document(userId)
                    .updateData([
                        "particleEffects": FieldValue.arrayUnion([particleId])
                    ])

                // UserManager 업데이트
                await refreshUserData()
            }
        }

        // 다운로드 상태 초기화
        downloadingItemIds.remove(particleId)
        downloadProgress.removeValue(forKey: particleId)
    }

    /// UserManager의 유저 데이터 새로고침
    private func refreshUserData() async {
        guard let userId = userManager.currentUser?.id else { return }

        await withCheckedContinuation { continuation in
            userManager.loadUserInfo(uid: userId) { _ in
                continuation.resume()
            }
        }
    }
}
