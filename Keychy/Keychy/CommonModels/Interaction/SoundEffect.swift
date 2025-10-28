//
//  Sound.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

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
