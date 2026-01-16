//
//  KeyringVideoGenerator+Keyring.swift
//  Keychy
//
//  Created by 길지훈 on 1/15/26.
//

import Foundation
import UIKit
import Combine

// MARK: - Keyring Model Support

extension KeyringVideoGenerator {

    /// 키링 모델로부터 영상 생성 (컬렉션 뷰에서 사용)
    /// - Parameters:
    ///   - keyring: 키링 모델
    ///   - backgroundImage: 배경 이미지
    ///   - keyringScale: 키링 확대 배율
    /// - Returns: 생성된 영상 파일 URL
    func generateVideo(
        keyring: Keyring,
        backgroundImage: UIImage? = UIImage(named: "completeBG2"),
        keyringScale: CGFloat = 3.5
    ) async throws -> URL {
        // Keyring 모델을 래핑하는 어댑터 생성
        let adapter = KeyringAdapter(keyring: keyring)

        // 기존 메서드 호출
        return try await generateVideo(
            viewModel: adapter,
            backgroundImage: backgroundImage,
            keyringScale: keyringScale
        )
    }
}

// MARK: - Keyring Adapter

/// Keyring 모델을 KeyringViewModelProtocol로 변환하는 어댑터
/// 영상 생성 시에만 사용되며, 최소한의 프로토콜 요구사항만 구현
@Observable
private class KeyringAdapter: KeyringViewModelProtocol {

    let keyring: Keyring

    init(keyring: Keyring) {
        self.keyring = keyring
    }

    // MARK: - KeyringViewModelProtocol 구현

    var nameText: String {
        get { keyring.name }
        set { }
    }

    var maxTextCount: Int { 10 }

    var memoText: String {
        get { keyring.memo ?? "" }
        set { }
    }

    var maxMemoCount: Int { 100 }

    var createdAt: Date {
        get { keyring.createdAt }
        set { }
    }

    var selectedTags: [String] {
        get { keyring.tags }
        set { }
    }

    var bodyImage: UIImage? {
        // URL 문자열을 UIImage로 변환 (동기 처리)
        guard let url = URL(string: keyring.bodyImage),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    var hookOffsetY: CGFloat {
        get { keyring.hookOffsetY ?? 0 }
        set { }
    }

    var chainLength: Int {
        keyring.chainLength
    }

    var templateId: String {
        keyring.selectedTemplate
    }

    var availableCustomizingModes: [CustomizingMode] {
        [.effect]
    }

    var availableSounds: [Sound] { [] }
    var availableParticles: [Particle] { [] }
    var sortedAvailableSounds: [Sound] { [] }
    var sortedAvailableParticles: [Particle] { [] }

    var selectedSound: Sound? {
        get { nil }
        set { }
    }

    var selectedParticle: Particle? {
        get { nil }
        set { }
    }

    var customSoundURL: URL? {
        get { nil }
        set { }
    }

    var hasCustomSound: Bool { false }

    var downloadingItemIds: Set<String> {
        get { [] }
        set { }
    }

    var downloadProgress: [String: Double] {
        get { [:] }
        set { }
    }

    var soundId: String {
        get { keyring.soundId }
        set { }
    }

    var particleId: String {
        get { keyring.particleId }
        set { }
    }

    var effectSubject: PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never> {
        PassthroughSubject()
    }

    func updateSound(_ sound: Sound?) { }
    func updateParticle(_ particle: Particle?) { }
    func applyCustomSound(_ url: URL) { }
    func removeCustomSound() { }
    func fetchEffects() async { }
    func isOwned(soundId: String) -> Bool { false }
    func isOwned(particleId: String) -> Bool { false }
    func isInBundle(soundId: String) -> Bool { false }
    func isInBundle(particleId: String) -> Bool { false }
    func isInCache(soundId: String) -> Bool { false }
    func isInCache(particleId: String) -> Bool { false }
    func downloadSound(_ sound: Sound) async { }
    func downloadParticle(_ particle: Particle) async { }
    func resetCustomizingData() { }
    func resetInfoData() { }
    func resetAll() { }
}
