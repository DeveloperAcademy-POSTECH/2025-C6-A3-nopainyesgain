//
//  KeyringScene+Effects.swift
//  KeytschPrototype
//
//  Created by rundo on 10/22/25.
//

import AVFoundation

extension KeyringScene {
    func applySoundEffect(soundId: String) {
        guard soundId != "none" else { return }

        // Firebase Storage URL인 경우 (커스텀 사운드가 저장된 경우)
        if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
            if let url = URL(string: soundId) {
                SoundEffectComponent.shared.playSound(from: url)
            }
            return
        }

        // 로컬 커스텀 녹음 파일인 경우
        if soundId == "custom_recording", let customURL = customSoundURL {
            SoundEffectComponent.shared.playSound(from: customURL)
            return
        }

        // 일반 사운드 파일
        SoundEffectComponent.shared.playSound(named: soundId)
    }

    func applyParticleEffect(particleId: String) {
        guard particleId != "none" else { return }
        onPlayParticleEffect?(particleId)
    }
}

// MARK: - SoundEffectComponent
class SoundEffectComponent {
    static let shared = SoundEffectComponent()
    private init() {}

    // 사운드 파일들을 미리 로드해서 저장
    private var audioPlayers: [String: AVAudioPlayer] = [:]

    // 커스텀 사운드 플레이어 (strong reference 유지)
    private var customAudioPlayer: AVAudioPlayer?

    // 스레드 안전성을 위한 직렬 큐
    private let audioQueue = DispatchQueue(label: "com.keychy.audioQueue", qos: .userInteractive)

    /// 사운드 파일 미리 로드 (백그라운드에서 실행)
    /// soundId로 로컬 캐시 → Bundle 순서로 파일을 찾음
    func preloadSound(named soundId: String, type: String = "mp3") async {
        await withCheckedContinuation { continuation in
            audioQueue.async { [weak self] in
                guard let url = self?.findSoundURL(soundId: soundId, type: type) else {
                    continuation.resume()  // 파일 없으면 계속 진행
                    return
                }

                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()  // 미리 준비
                    self?.audioPlayers[soundId] = player
                    continuation.resume()  // 완료!
                } catch {
                    print("Error preloading sound: \(error.localizedDescription)")
                    continuation.resume()  // 에러나도 계속 진행
                }
            }
        }
    }

    /// 미리 로드된 사운드 재생 (백그라운드 스레드에서 실행)
    /// soundId로 로컬 캐시 → Bundle 순서로 파일을 찾음
    func playSound(named soundId: String, type: String = "mp3") {
        // 직렬 큐에서 실행 → 메인 스레드 블로킹 방지 + 스레드 안전성 보장
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            // 로드된 audioPlayers에 있으면 바로 재생
            if let player = self.audioPlayers[soundId] {
                player.currentTime = 0  // 처음부터 재생
                player.play()
                return
            }

            // 없으면 즉시 로드해서 재생 (예외처리)
            guard let url = self.findSoundURL(soundId: soundId, type: type) else {
                print("Sound file not found: \(soundId)")
                return
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                self.audioPlayers[soundId] = player  // 다음을 위해 저장
                player.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        }
    }

    /// URL 기반 사운드 재생 (커스텀 녹음 파일용)
    func playSound(from url: URL) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                // 오디오 세션 활성화 (재생용)
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try audioSession.setActive(true)

                // 원격 URL인 경우 다운로드 후 재생
                if url.scheme == "https" || url.scheme == "http" {
                    self.downloadAndPlay(url: url)
                } else {
                    // 로컬 파일인 경우 바로 재생
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    self.customAudioPlayer = player
                    player.play()
                }
            } catch {
                print("Error playing custom sound: \(error.localizedDescription)")
            }
        }
    }

    /// 원격 사운드 다운로드 후 재생
    private func downloadAndPlay(url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Error downloading sound: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // 임시 파일로 저장
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".m4a")

            do {
                try data.write(to: tempURL)

                // 재생
                let player = try AVAudioPlayer(contentsOf: tempURL)
                player.prepareToPlay()
                self.customAudioPlayer = player
                player.play()

                // 재생 완료 후 임시 파일 삭제
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    try? FileManager.default.removeItem(at: tempURL)
                }
            } catch {
                print("Error saving/playing downloaded sound: \(error.localizedDescription)")
            }
        }
        task.resume()
    }

    /// 사운드 파일 URL 찾기 (캐시 → Bundle 순서)
    private func findSoundURL(soundId: String, type: String) -> URL? {
        // 1. 로컬 캐시에서 찾기
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("sounds/\(soundId).\(type)")

        if FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }

        // 2. Bundle에서 찾기 (기본 무료 사운드)
        if let bundleURL = Bundle.main.url(forResource: soundId, withExtension: type) {
            return bundleURL
        }

        return nil
    }
}

