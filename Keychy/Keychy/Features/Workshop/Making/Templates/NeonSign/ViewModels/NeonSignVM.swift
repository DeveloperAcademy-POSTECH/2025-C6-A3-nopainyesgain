//
//  NeonSignVM.swift
//  Keychy
//
//  Created by Rundo on 11/8/25.
// 설명: 네온 사인 템플릿 뷰모델
// 이미지 선택 없이 미리 정의된 bodyImage 사용 + 이펙트 선택

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class NeonSignVM: KeyringViewModelProtocol {
    // MARK: - Template Data (Firebase)
    var template: KeyringTemplate?
    var isLoadingTemplate = false

    // MARK: - Effect Data (Firebase)
    var availableSounds: [Sound] = []
    var availableParticles: [Particle] = []

    /// 정렬된 사운드 리스트
    var sortedAvailableSounds: [Sound] {
        availableSounds.sorted { sound1, sound2 in
            guard let id1 = sound1.id, let id2 = sound2.id else { return false }

            let downloaded1 = isInBundle(soundId: id1) || isInCache(soundId: id1)
            let downloaded2 = isInBundle(soundId: id2) || isInCache(soundId: id2)

            let priority1 = getSortPriority(
                isFree: sound1.isFree,
                isDownloaded: downloaded1
            )
            let priority2 = getSortPriority(
                isFree: sound2.isFree,
                isDownloaded: downloaded2
            )

            return priority1 < priority2
        }
    }

    /// 정렬된 파티클 리스트
    var sortedAvailableParticles: [Particle] {
        availableParticles.sorted { particle1, particle2 in
            guard let id1 = particle1.id, let id2 = particle2.id else { return false }

            let downloaded1 = isInBundle(particleId: id1) || isInCache(particleId: id1)
            let downloaded2 = isInBundle(particleId: id2) || isInCache(particleId: id2)

            let priority1 = getSortPriority(
                isFree: particle1.isFree,
                isDownloaded: downloaded1
            )
            let priority2 = getSortPriority(
                isFree: particle2.isFree,
                isDownloaded: downloaded2
            )

            return priority1 < priority2
        }
    }

    var selectedSound: Sound? = nil
    var selectedParticle: Particle? = nil

    // MARK: - Custom Sound (녹음)
    var customSoundURL: URL? = nil

    // MARK: - Download State
    var downloadingItemIds: Set<String> = []
    var downloadProgress: [String: Double] = [:]

    // MARK: - Scene 전달용 ID
    var soundId: String = "none"
    var particleId: String = "none"

    // MARK: - Combine Bridge
    /// @Observable을 Combine에 사용하기 위한 브릿지
    /// KeyringScene에 soundId, particleId만 전달
    let effectSubject = PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never>()

    // MARK: - UserManager
    var userManager: UserManager

    // MARK: - Body Image (템플릿에 미리 정의된 이미지)
    var bodyImage: UIImage? = nil
    var originalBodyImage: UIImage? = nil  // 원본 이미지 (합성 전)
    var hookOffsetY: CGFloat = 0.0

    /// 템플릿 ID
    var templateId: String {
        template?.id ?? "NeonSign"
    }

    var errorMessage: String?

    // MARK: - Drawing State (그리기 모드)
    var drawingPaths: [DrawnPath] = []
    var currentDrawingColor: Color = .white
    var currentLineWidth: CGFloat = 3.0
    var imageFrame: CGRect = .zero  // 그리기 영역 (DrawingCanvasView에서 설정)

    // MARK: - 정보 입력
    var nameText: String = ""
    var maxTextCount: Int = 30
    var memoText: String = ""
    var maxMemoCount: Int = 500
    var selectedTags: [String] = []
    var createdAt: Date = Date()

    // MARK: - 초기화
    init(userManager: UserManager = UserManager.shared) {
        self.userManager = userManager
    }

    // MARK: - 생성일 Date formatter
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: createdAt)
    }

    // MARK: - Firebase Template 가져오기
    func fetchTemplate() async {
        isLoadingTemplate = true

        defer { isLoadingTemplate = false }

        do {
            let document = try await Firestore.firestore()
                .collection("Template")
                .document("NeonSign")
                .getDocument()

            template = try document.data(as: KeyringTemplate.self)

            // 네온사인 템플릿 전용 고정 이미지 (Assets)
            let image = UIImage(named: "bangMark")
            bodyImage = image
            originalBodyImage = image  // 원본 저장

        } catch {
            errorMessage = "템플릿을 불러오는데 실패했습니다."
        }
    }

    // MARK: - Firebase Effects 가져오기 (전체 - 소유/미소유 분리)
    func fetchEffects() async {
        guard let user = userManager.currentUser else {
            errorMessage = "유저 정보를 불러올 수 없습니다."
            return
        }

        do {
            // Sound 전체 가져오기 (isActive == true만)
            let soundsSnapshot = try await Firestore.firestore()
                .collection("Sound")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            let allSounds = try soundsSnapshot.documents.compactMap {
                try $0.data(as: Sound.self)
            }

            // 소유/미소유 분리 및 정렬
            let ownedSounds = allSounds.filter { sound in
                guard let id = sound.id else { return false }
                return user.soundEffects.contains(id)
            }
            let notOwnedSounds = allSounds.filter { sound in
                guard let id = sound.id else { return false }
                return !user.soundEffects.contains(id)
            }

            availableSounds = ownedSounds + notOwnedSounds

            // Particle 전체 가져오기 (isActive == true만)
            let particlesSnapshot = try await Firestore.firestore()
                .collection("Particle")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            let allParticles = try particlesSnapshot.documents.compactMap {
                try $0.data(as: Particle.self)
            }

            // 소유/미소유 분리 및 정렬
            let ownedParticles = allParticles.filter { particle in
                guard let id = particle.id else { return false }
                return user.particleEffects.contains(id)
            }
            let notOwnedParticles = allParticles.filter { particle in
                guard let id = particle.id else { return false }
                return !user.particleEffects.contains(id)
            }

            availableParticles = ownedParticles + notOwnedParticles

        } catch {
            errorMessage = "이펙트 목록을 불러오는데 실패했습니다."
        }
    }

    // MARK: - Sorting Helper
    private func getSortPriority(isFree: Bool, isDownloaded: Bool) -> Int {
        if isFree && isDownloaded { return 1 }
        if !isFree && isDownloaded { return 2 }
        if isFree && !isDownloaded { return 3 }
        if !isFree && !isDownloaded { return 4 }
        return 99
    }

    // MARK: - Lifecycle Callbacks
    /// 모드 변경 시 그리기 → 다른 모드로 전환되면 그림 합성
    func onModeChanged(from oldMode: CustomizingMode, to newMode: CustomizingMode) {
        if oldMode == .drawing && newMode != .drawing {
            composeDrawingWithBodyImage()
        }
    }

    /// 다음 화면으로 이동하기 전 그림 합성
    func beforeNavigateToNext() {
        composeDrawingWithBodyImage()
    }

    // MARK: - Customizing Modes
    /// 커스터마이징 모드 (네온 사인은 그리기 + 이펙트 지원)
    var availableCustomizingModes: [CustomizingMode] {
        [.drawing, .effect]
    }

    // MARK: - View Providers
    /// 씬 뷰 제공 (모드별)
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
        case .drawing:
            return AnyView(DrawingCanvasView(viewModel: self))
        }
    }

    /// 하단 콘텐츠 뷰 제공 (모드별)
    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(EffectSelectorView(viewModel: self, cartItems: cartItems))
        case .drawing:
            return AnyView(DrawingToolsView(viewModel: self))
        }
    }

    // MARK: - Reset
    /// 커스터마이징 데이터 초기화 (이펙트 + 그리기)
    func resetCustomizingData() {
        // 이펙트 초기화
        selectedSound = nil
        selectedParticle = nil
        customSoundURL = nil
        soundId = "none"
        particleId = "none"
        downloadingItemIds.removeAll()
        downloadProgress.removeAll()

        // 그리기 상태 초기화
        drawingPaths.removeAll()
        currentDrawingColor = .white
        currentLineWidth = 3.0

        // 원본 이미지로 복원
        if let original = originalBodyImage {
            bodyImage = original
        }
    }

    /// 정보 입력 데이터 초기화
    func resetInfoData() {
        nameText = ""
        memoText = ""
        selectedTags = []
    }

    /// 완전 초기화
    func resetAll() {
        resetCustomizingData()
        resetInfoData()
    }
}
