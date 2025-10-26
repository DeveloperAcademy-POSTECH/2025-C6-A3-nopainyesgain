//
//  Sound.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import AVFoundation

enum SoundEffect: String, CaseIterable {
    case none
    case drum
    case shutter

    var soundFileName: String {
        switch self {
        case .none:
            return "none"
        case .drum:
            return "drumSoundFile"
        case .shutter:
            return "shutterSoundFile"
        }
    }
    
    var title: String {
        switch self {
        case .none: return "없음"
        case .drum: return "드럼"
        case .shutter: return "셔터"
        }
    }
}

// mp3 파일 이름을 받으면 재생해주는 로직 함수
class SoundEffectComponent {
    static let shared = SoundEffectComponent()
    private init() {}

    var player: AVAudioPlayer?

    func playSound(named soundName: String, type: String = "mp3") {
        if let url = Bundle.main.url(forResource: soundName, withExtension: type) {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found")
        }
    }
}
