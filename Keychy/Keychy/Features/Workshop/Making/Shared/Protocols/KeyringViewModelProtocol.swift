//
//  KeyringViewModelProtocol.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/26/25.
//

import SwiftUI
import Combine

protocol KeyringViewModelProtocol: AnyObject, Observable {
    // MARK: - 키링 기본 정보들
    var nameText: String { get set }
    var maxTextCount: Int { get }
    var memoText: String { get set }
    var maxMemoCount: Int { get }
    var createdAt: Date { get set }

    /// 태그 관련
    var selectedTags: [String] { get set }

    /// 키링 바디 이미지 (혹시나 특이한 템플릿이 있다면 안쓸수도 있어서 Optional)
    var bodyImage: UIImage? { get }

    /// 이펙트 관련
    var soundId: String { get set }
    var particleId: String { get set }
    var effectSubject: PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never> { get }

    // MARK: - Methods
    func updateSoundEffect(_ effect: SoundEffect)
    func updateParticleEffect(_ effect: ParticleEffect)
}
