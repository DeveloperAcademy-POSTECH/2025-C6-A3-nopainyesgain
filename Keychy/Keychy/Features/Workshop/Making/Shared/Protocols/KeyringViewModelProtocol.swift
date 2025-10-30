//
//  KeyringViewModelProtocol.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/26/25.
//

import SwiftUI
import Combine

/// 키링 커스터마이징 모드
enum CustomizingMode: String, CaseIterable, Identifiable {
    case effect = "이펙트"
    // 나중에 추가 가능: case drawing = "그리기"

    var id: String { rawValue }

    /// 버튼 이미지
    var btnImage: String {
        switch self {
        case .effect:
            return "interactionSelector"
        }
    }
}

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

    /// 커스터마이징 모드 (템플릿마다 다름)
    var availableCustomizingModes: [CustomizingMode] { get }

    /// 이펙트 관련 - Firebase 데이터
    var availableSounds: [Sound] { get }
    var availableParticles: [Particle] { get }

    /// 선택된 이펙트
    var selectedSound: Sound? { get set }
    var selectedParticle: Particle? { get set }

    /// 다운로드 상태 관리
    var downloadingItemIds: Set<String> { get set }
    var downloadProgress: [String: Double] { get set }

    /// Scene 전달용 ID
    var soundId: String { get set }
    var particleId: String { get set }
    var effectSubject: PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never> { get }

    // MARK: - Methods
    func updateSound(_ sound: Sound?)
    func updateParticle(_ particle: Particle?)

    /// Firebase Effects 가져오기
    func fetchEffects() async

    /// 소유 여부 확인 (Firebase 구매 기록)
    func isOwned(soundId: String) -> Bool
    func isOwned(particleId: String) -> Bool

    /// Bundle에 포함 여부 (앱에 포함된 무료 아이템)
    func isInBundle(soundId: String) -> Bool
    func isInBundle(particleId: String) -> Bool

    /// Cache에 다운로드 여부 (다운로드한 아이템)
    func isInCache(soundId: String) -> Bool
    func isInCache(particleId: String) -> Bool

    /// 다운로드
    func downloadSound(_ sound: Sound) async
    func downloadParticle(_ particle: Particle) async
}
