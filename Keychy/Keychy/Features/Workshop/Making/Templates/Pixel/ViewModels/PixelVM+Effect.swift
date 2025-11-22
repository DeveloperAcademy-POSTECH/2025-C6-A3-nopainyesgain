//
//  PixelKeyringVM+Effect.swift
//  Keychy
//
//  Created by 길지훈 on 11/22/25.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Effect Management
extension PixelVM {
    // MARK: - 커스텀 사운드
    var hasCustomSound: Bool {
        customSoundURL != nil
    }

    func applyCustomSound(_ url: URL) {
        customSoundURL = url
        selectedSound = nil
        soundId = url.absoluteString
        effectSubject.send((soundId: soundId, particleId: particleId, type: .sound))
    }

    func removeCustomSound() {
        customSoundURL = nil
        soundId = "none"
        effectSubject.send((soundId: soundId, particleId: particleId, type: .sound))
    }

    // MARK: - 이펙트 업데이트
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

    // MARK: - 소유 여부 확인
    func isOwned(soundId: String) -> Bool {
        guard let user = userManager.currentUser else { return false }
        return user.soundEffects.contains(soundId)
    }

    func isOwned(particleId: String) -> Bool {
        guard let user = userManager.currentUser else { return false }
        return user.particleEffects.contains(particleId)
    }

    // MARK: - Bundle 포함 여부
    func isInBundle(soundId: String) -> Bool {
        guard let path = Bundle.main.path(forResource: soundId, ofType: "mp3") else {
            return false
        }
        return FileManager.default.fileExists(atPath: path)
    }

    func isInBundle(particleId: String) -> Bool {
        guard let path = Bundle.main.path(forResource: particleId, ofType: "json") else {
            return false
        }
        return FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Cache 확인
    func isInCache(soundId: String) -> Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent("Sounds/\(soundId).mp3")
        return FileManager.default.fileExists(atPath: filePath.path)
    }

    func isInCache(particleId: String) -> Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent("Particles/\(particleId).json")
        return FileManager.default.fileExists(atPath: filePath.path)
    }

    // MARK: - 다운로드
    func downloadSound(_ sound: Sound) async {
        let urlString = sound.soundData
        guard let id = sound.id else { return }
        guard let url = URL(string: urlString) else { return }

        downloadingItemIds.insert(id)
        downloadProgress[id] = 0.0

        defer {
            downloadingItemIds.remove(id)
            downloadProgress.removeValue(forKey: id)
        }

        do {
            let (localURL, _) = try await URLSession.shared.download(from: url)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let soundsDirectory = documentsPath.appendingPathComponent("Sounds")

            try? FileManager.default.createDirectory(at: soundsDirectory, withIntermediateDirectories: true)

            let destinationURL = soundsDirectory.appendingPathComponent("\(id).mp3")

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.moveItem(at: localURL, to: destinationURL)
            print("Sound downloaded: \(id)")
        } catch {
            print("Sound download failed: \(error)")
        }
    }

    func downloadParticle(_ particle: Particle) async {
        let urlString = particle.particleData
        guard let id = particle.id else { return }
        guard let url = URL(string: urlString) else { return }
        
        downloadingItemIds.insert(id)
        downloadProgress[id] = 0.0

        defer {
            downloadingItemIds.remove(id)
            downloadProgress.removeValue(forKey: id)
        }

        do {
            let (localURL, _) = try await URLSession.shared.download(from: url)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let particlesDirectory = documentsPath.appendingPathComponent("Particles")

            try? FileManager.default.createDirectory(at: particlesDirectory, withIntermediateDirectories: true)

            let destinationURL = particlesDirectory.appendingPathComponent("\(id).json")

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.moveItem(at: localURL, to: destinationURL)
            print("Particle downloaded: \(id)")
        } catch {
            print("Particle download failed: \(error)")
        }
    }

    // MARK: - Reset Methods
    func resetCustomizingData() {
        selectedSound = nil
        selectedParticle = nil
        customSoundURL = nil
        soundId = "none"
        particleId = "none"
    }

    func resetInfoData() {
        nameText = ""
        memoText = ""
        selectedTags = []
        createdAt = Date()
    }
}
