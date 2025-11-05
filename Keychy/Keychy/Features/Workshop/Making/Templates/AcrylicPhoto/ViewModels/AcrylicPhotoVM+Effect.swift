//
//  AcrylicPhotoVM+Effect.swift
//  KeytschPrototype
//
//  Created by rundo on 10/22/25.
//

import Combine
import Foundation

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
        return EffectManager.shared.isOwned(soundId: soundId, userManager: userManager)
    }

    /// 파티클 소유 여부 확인 (Firebase 구매 기록)
    func isOwned(particleId: String) -> Bool {
        return EffectManager.shared.isOwned(particleId: particleId, userManager: userManager)
    }

    /// 사운드가 Bundle에 포함되어 있는지 (앱에 포함된 무료 아이템)
    func isInBundle(soundId: String) -> Bool {
        return EffectManager.shared.isInBundle(soundId: soundId)
    }

    /// 파티클이 Bundle에 포함되어 있는지 (앱에 포함된 무료 아이템)
    func isInBundle(particleId: String) -> Bool {
        return EffectManager.shared.isInBundle(particleId: particleId)
    }

    /// 사운드가 Cache에 다운로드되어 있는지
    func isInCache(soundId: String) -> Bool {
        return EffectManager.shared.isInCache(soundId: soundId)
    }

    /// 파티클이 Cache에 다운로드되어 있는지
    func isInCache(particleId: String) -> Bool {
        return EffectManager.shared.isInCache(particleId: particleId)
    }

    // MARK: - Download (EffectManager 위임)

    /// 사운드 다운로드
    func downloadSound(_ sound: Sound) async {
        guard let soundId = sound.id else { return }

        // ViewModel 상태 시작
        await MainActor.run {
            downloadingItemIds.insert(soundId)
            downloadProgress[soundId] = 0.0
        }

        // Progress 모니터링 Task
        let monitorTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    // EffectManager의 progress를 ViewModel에 복사
                    if let progress = EffectManager.shared.downloadProgress[soundId] {
                        downloadProgress[soundId] = progress
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초마다 확인
            }
        }

        // EffectManager를 통해 다운로드
        await EffectManager.shared.downloadSound(sound, userManager: userManager)

        // 모니터링 중단
        monitorTask.cancel()

        // 다운로드 완료 후 상태 정리 및 자동 선택
        await MainActor.run {
            downloadingItemIds.remove(soundId)
            downloadProgress.removeValue(forKey: soundId)
            updateSound(sound)
        }
    }

    /// 파티클 다운로드
    func downloadParticle(_ particle: Particle) async {
        guard let particleId = particle.id else { return }

        // ViewModel 상태 시작
        await MainActor.run {
            downloadingItemIds.insert(particleId)
            downloadProgress[particleId] = 0.0
        }

        // Progress 모니터링 Task
        let monitorTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    // EffectManager의 progress를 ViewModel에 복사
                    if let progress = EffectManager.shared.downloadProgress[particleId] {
                        downloadProgress[particleId] = progress
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초마다 확인
            }
        }

        // EffectManager를 통해 다운로드
        await EffectManager.shared.downloadParticle(particle, userManager: userManager)

        // 모니터링 중단
        monitorTask.cancel()

        // 다운로드 완료 후 상태 정리 및 자동 선택
        await MainActor.run {
            downloadingItemIds.remove(particleId)
            downloadProgress.removeValue(forKey: particleId)
            updateParticle(particle)
        }
    }
}
