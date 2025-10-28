//
//  MKViewModel+Effect.swift
//  KeytschPrototype
//
//  Created by rundo on 10/22/25.
//

import Combine

extension AcrylicPhotoVM {
    /// 사운드 이펙트 업데이트
    func updateSoundEffect(_ effect: SoundEffect) {
        keyring.soundId = effect.soundFileName
        keyringSubject.send((keyring, .sound))
    }

    /// 파티클 이펙트 업데이트
    func updateParticleEffect(_ effect: ParticleEffect) {
        keyring.particleId = effect.effectFileName
        keyringSubject.send((keyring, .particle))
    }
}
