//
//  KeyringScene+Effects.swift
//  KeytschPrototype
//
//  Created by rundo on 10/22/25.
//

import AVFoundation

extension KeyringScene {
    func applySoundEffect(for keyring: Keyring) {
        guard keyring.soundId != "none" else { return }
        SoundEffectComponent.shared.playSound(named: keyring.soundId)
    }

    func applyParticleEffect(for keyring: Keyring) {
        guard keyring.particleId != "none" else { return }
        onPlayParticleEffect?(keyring.particleId)
    }
}

// MARK: - SoundEffectComponent
class SoundEffectComponent {
    static let shared = SoundEffectComponent()
    private init() {}

    // 사운드 파일들을 미리 로드해서 저장
    private var audioPlayers: [String: AVAudioPlayer] = [:]

    // 스레드 안전성을 위한 직렬 큐
    private let audioQueue = DispatchQueue(label: "com.keychy.audioQueue", qos: .userInteractive)

    /// 앱 시작 시 사운드 파일 미리 로드 (백그라운드에서 실행)
    func preloadSound(named soundName: String, type: String = "mp3") {
        audioQueue.async { [weak self] in
            // TODO: Firebase 연동 시 변경 필요
            // 현재: 로컬 Bundle에서 가져오기
            // 변경 후: Firebase Storage에서 다운로드
            //   1. Firebase Storage에서 mp3 파일 다운로드 (URL: "sounds/{soundName}.mp3")
            //   2. 로컬 캐시 디렉토리에 저장
            //   3. 캐시된 파일 URL로 AVAudioPlayer 생성
            //   4. 다음번엔 캐시부터 확인 → 있으면 캐시 사용, 없으면 다운로드
            guard let url = Bundle.main.url(forResource: soundName, withExtension: type) else {
                return
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()  // 미리 준비
                self?.audioPlayers[soundName] = player
            } catch {
                print("Error preloading sound: \(error.localizedDescription)")
            }
        }
    }

    /// 미리 로드된 사운드 재생 (백그라운드 스레드에서 실행)
    /// TODO: Firebase 연동 시 변경 필요 (preloadSound()와 동일한 로직)
    func playSound(named soundName: String, type: String = "mp3") {
        // 직렬 큐에서 실행 → 메인 스레드 블로킹 방지 + 스레드 안전성 보장
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            // 로드된 audioPlayers에 있으면 바로 재생
            if let player = self.audioPlayers[soundName] {
                player.currentTime = 0  // 처음부터 재생
                player.play()
                return
            }

            // 없으면 즉시 로드해서 재생 (예외처리)
            guard let url = Bundle.main.url(forResource: soundName, withExtension: type) else {
                return
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                self.audioPlayers[soundName] = player  // 다음을 위해 저장
                player.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        }
    }
}

