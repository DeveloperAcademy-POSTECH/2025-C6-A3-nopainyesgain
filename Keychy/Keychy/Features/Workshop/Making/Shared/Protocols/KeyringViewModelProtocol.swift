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

    /// 정렬된 이펙트 리스트 (무료 다운로드됨 → 무료 미다운로드 → 유료 보유 다운로드됨 → 유료 보유 미다운로드 → 유료 미보유)
    var sortedAvailableSounds: [Sound] { get }
    var sortedAvailableParticles: [Particle] { get }

    /// 선택된 이펙트
    var selectedSound: Sound? { get set }
    var selectedParticle: Particle? { get set }

    /// 커스텀 사운드 (녹음)
    var customSoundURL: URL? { get set }
    var hasCustomSound: Bool { get }

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

    /// 커스텀 사운드 적용
    func applyCustomSound(_ url: URL)
    func removeCustomSound()

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

    // MARK: - Reset Methods
    /// 이미지 데이터 초기화 (크롭뷰 뒤로가기)
    func resetImageData()

    /// 커스터마이징 데이터 초기화 (이펙트, 커스텀 사운드)
    func resetCustomizingData()

    /// 정보 입력 데이터 초기화 (정보입력뷰 뒤로가기)
    func resetInfoData()

    /// 완전 초기화 (완성뷰 dismiss, 커스터마이징뷰 alert 후)
    func resetAll()
}
