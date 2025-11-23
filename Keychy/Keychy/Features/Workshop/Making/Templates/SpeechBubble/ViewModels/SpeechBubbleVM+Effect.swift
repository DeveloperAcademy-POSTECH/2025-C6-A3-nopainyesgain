//
//  SpeechBubbleVM+Effect.swift
//  Keychy
//
//  Created by 길지훈 on 11/23/25.
//

import Combine
import Foundation

extension SpeechBubbleVM {
    
    // MARK: - Sorted Lists
    
    var sortedAvailableSounds: [Sound] {
        availableSounds.sorted { sound1, sound2 in
            guard let id1 = sound1.id, let id2 = sound2.id else { return false }
            
            let downloaded1 = isInBundle(soundId: id1) || isInCache(soundId: id1)
            let downloaded2 = isInBundle(soundId: id2) || isInCache(soundId: id2)
            
            let priority1 = getSortPriority(
                isFree: sound1.isFree,
                isDownloaded: downloaded1
            )
            let priority2 = getSortPriority(
                isFree: sound2.isFree,
                isDownloaded: downloaded2
            )
            
            return priority1 < priority2
        }
    }
    
    var sortedAvailableParticles: [Particle] {
        availableParticles.sorted { particle1, particle2 in
            guard let id1 = particle1.id, let id2 = particle2.id else { return false }
            
            let downloaded1 = isInBundle(particleId: id1) || isInCache(particleId: id1)
            let downloaded2 = isInBundle(particleId: id2) || isInCache(particleId: id2)
            
            let priority1 = getSortPriority(
                isFree: particle1.isFree,
                isDownloaded: downloaded1
            )
            let priority2 = getSortPriority(
                isFree: particle2.isFree,
                isDownloaded: downloaded2
            )
            
            return priority1 < priority2
        }
    }
    
    // MARK: - Sound & Particle Update
    
    func updateSound(_ sound: Sound?) {
        selectedSound = sound
        customSoundURL = nil
        
        if let sound = sound, let id = sound.id {
            soundId = id
        } else {
            soundId = "none"
        }
        
        effectSubject.send((soundId: soundId, particleId: particleId, type: .sound))
    }
    
    func updateParticle(_ particle: Particle?) {
        selectedParticle = particle
        
        if let particle = particle, let id = particle.id {
            particleId = id
        } else {
            particleId = "none"
        }
        
        effectSubject.send((soundId: soundId, particleId: particleId, type: .particle))
    }
    
    // MARK: - Custom Sound (녹음)
    
    var hasCustomSound: Bool {
        customSoundURL != nil
    }
    
    func applyCustomSound(_ url: URL) {
        customSoundURL = url
        selectedSound = nil
        soundId = "custom_recording"
        effectSubject.send((soundId: soundId, particleId: particleId, type: .sound))
    }
    
    func removeCustomSound() {
        customSoundURL = nil
        soundId = "none"
        effectSubject.send((soundId: soundId, particleId: particleId, type: .sound))
    }
    
    // MARK: - Ownership Check
    
    func isOwned(soundId: String) -> Bool {
        return EffectManager.shared.isOwned(soundId: soundId, userManager: userManager)
    }
    
    func isOwned(particleId: String) -> Bool {
        return EffectManager.shared.isOwned(particleId: particleId, userManager: userManager)
    }
    
    func isInBundle(soundId: String) -> Bool {
        return EffectManager.shared.isInBundle(soundId: soundId)
    }
    
    func isInBundle(particleId: String) -> Bool {
        return EffectManager.shared.isInBundle(particleId: particleId)
    }
    
    func isInCache(soundId: String) -> Bool {
        return EffectManager.shared.isInCache(soundId: soundId)
    }
    
    func isInCache(particleId: String) -> Bool {
        return EffectManager.shared.isInCache(particleId: particleId)
    }
    
    // MARK: - Download
    
    func downloadSound(_ sound: Sound) async {
        guard let soundId = sound.id else { return }
        
        await MainActor.run {
            downloadingItemIds.insert(soundId)
            downloadProgress[soundId] = 0.0
        }
        
        let monitorTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    if let progress = EffectManager.shared.downloadProgress[soundId] {
                        downloadProgress[soundId] = progress
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        
        await EffectManager.shared.downloadSound(sound, userManager: userManager)
        monitorTask.cancel()
        
        await MainActor.run {
            downloadingItemIds.remove(soundId)
            downloadProgress.removeValue(forKey: soundId)
            updateSound(sound)
        }
    }
    
    func downloadParticle(_ particle: Particle) async {
        guard let particleId = particle.id else { return }
        
        await MainActor.run {
            downloadingItemIds.insert(particleId)
            downloadProgress[particleId] = 0.0
        }
        
        let monitorTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    if let progress = EffectManager.shared.downloadProgress[particleId] {
                        downloadProgress[particleId] = progress
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        
        await EffectManager.shared.downloadParticle(particle, userManager: userManager)
        monitorTask.cancel()
        
        await MainActor.run {
            downloadingItemIds.remove(particleId)
            downloadProgress.removeValue(forKey: particleId)
            updateParticle(particle)
        }
    }
    
    // MARK: - Sorting Helper
    
    private func getSortPriority(isFree: Bool, isDownloaded: Bool) -> Int {
        if isFree && isDownloaded { return 1 }
        if !isFree && isDownloaded { return 2 }
        if isFree && !isDownloaded { return 3 }
        if !isFree && !isDownloaded { return 4 }
        return 99
    }
}
