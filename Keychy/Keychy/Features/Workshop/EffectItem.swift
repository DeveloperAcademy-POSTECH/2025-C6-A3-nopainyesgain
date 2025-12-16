//
//  EffectItem.swift
//  Keychy
//
//  장바구니용 이펙트 아이템 모델
//

import Foundation

/// 장바구니에 담기는 이펙트 아이템 (Sound 또는 Particle)
struct EffectItem: Identifiable, Equatable {
    let id: String
    let name: String
    let type: EffectType
    let price: Int
    let thumbnailURL: String

    /// Sound 모델에서 EffectItem 생성
    init(sound: Sound) {
        self.id = sound.id ?? ""
        self.name = sound.soundName
        self.type = .sound
        self.price = sound.price
        self.thumbnailURL = sound.thumbnail
    }

    /// Particle 모델에서 EffectItem 생성
    init(particle: Particle) {
        self.id = particle.id ?? ""
        self.name = particle.particleName
        self.type = .particle
        self.price = particle.price
        self.thumbnailURL = particle.thumbnail
    }
}

/// 이펙트 타입
enum EffectType: String {
    case sound = "사운드"
    case particle = "파티클"
}
