//
//  KeyringScene+Effects.swift
//  KeytschPrototype
//
//  Created by rundo on 10/22/25.
//

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

