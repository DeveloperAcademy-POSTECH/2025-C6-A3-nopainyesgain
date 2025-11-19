//
//  KeyringViewModelProtocol.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/26/25.
//

import SwiftUI
import Combine

// MARK: 키링 커스터마이징 모드 정의
enum CustomizingMode: String, CaseIterable, Identifiable {
    case effect = "이펙트"
    case drawing = "그리기"

    var id: String { rawValue }

    /// 버튼 이미지 (활성화/비활성화 상태에 따라 다른 이미지)
    func btnImage(isSelected: Bool) -> String {
        switch self {
        case .effect:
            return isSelected ? "effectMode_active" : "effectMode_inactive"
        case .drawing:
            return isSelected ? "drawing_active" : "drawing_inactive"
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

    /// 키링 훅 오프셋 (기본값 0)
    var hookOffsetY: CGFloat { get set }

    /// 템플릿 ID
    var templateId: String { get }

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

    // MARK: - View Providers (모드별 뷰 제공)
    /// 모드에 따른 씬 뷰 제공 (중앙 영역)
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView

    /// 모드에 따른 하단 콘텐츠 뷰 제공
    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView

    // MARK: - Reset Methods
    /// 커스터마이징 데이터 초기화 (이펙트, 커스텀 사운드)
    func resetCustomizingData()

    /// 정보 입력 데이터 초기화 (정보입력뷰 뒤로가기)
    func resetInfoData()

    /// 완전 초기화 (완성뷰 dismiss, 커스터마이징뷰 alert 후)
    func resetAll()

    // MARK: - Lifecycle Callbacks
    /// 모드 변경 시 호출 (템플릿별 처리 필요 시 구현)
    func onModeChanged(from oldMode: CustomizingMode, to newMode: CustomizingMode)

    /// 다음 화면으로 이동하기 전 호출 (템플릿별 처리 필요 시 구현)
    func beforeNavigateToNext()
}

// MARK: - 디폴트로 커스터마이징뷰에서 필요한 뷰
extension KeyringViewModelProtocol {
    /// 기본 구현: 아무것도 하지 않음 (필요한 템플릿에서 override)
    func onModeChanged(from oldMode: CustomizingMode, to newMode: CustomizingMode) {}

    /// 기본 구현: 아무것도 하지 않음 (필요한 템플릿에서 override)
    func beforeNavigateToNext() {}

    /// 기본 씬 뷰 제공 (effect 모드 기본 지원, 나머지는 각 템플릿에서 override)
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
        case .drawing:
            // 기본적으로는 지원하지 않음 (NeonSign 등에서 override)
            return AnyView(EmptyView())
        }
    }

    /// 기본 하단 콘텐츠 뷰 제공 (effect 모드 기본 지원, 나머지는 각 템플릿에서 override)
    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(
                EffectSelectorView(viewModel: self, cartItems: cartItems)
                    .cinematicAppear(delay: 0.3, duration: 1.0, style: .slideUp)
            )
        case .drawing:
            // 기본적으로는 지원하지 않음 (NeonSign 등에서 override)
            return AnyView(EmptyView())
        }
    }
}
