//
//  PolaroidVM.swift
//  Keychy
//
//  폴라로이드 템플릿 뷰모델
//  프레임 선택 + 이펙트 선택

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class PolaroidVM: KeyringViewModelProtocol {
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
    let effectSubject = PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never>()

    // MARK: - UserManager
    var userManager: UserManager

    // MARK: - Body Image
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0

    /// 템플릿 ID
    var templateId: String {
        template?.id ?? "Polaroid"
    }

    var errorMessage: String?

    // MARK: - Frame State (프레임 모드)
    var availableFrames: [Frame] = []
    var selectedFrame: Frame? = nil
    var selectedPhotoImage: UIImage? = nil

    // MARK: - Photo Transform State (사진 변환 상태)
    var photoScale: CGFloat = 1.0
    var photoRotation: Angle = .zero
    var photoOffset: CGSize = .zero

    // MARK: - Photo Composition State
    var isComposingPhoto: Bool = false

    /// 프로토콜 준수: 합성 진행 중 여부
    var isComposing: Bool {
        isComposingPhoto
    }

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

    // MARK: - Firebase Template 가져오기
    func fetchTemplate() async {
        isLoadingTemplate = true

        defer { isLoadingTemplate = false }

        do {
            let document = try await Firestore.firestore()
                .collection("Template")
                .document("Polaroid")
                .getDocument()

            template = try document.data(as: KeyringTemplate.self)

        } catch {
            errorMessage = "템플릿을 불러오는데 실패했습니다."
        }
    }

    // MARK: - Firebase Effects 가져오기
    func fetchEffects() async {
        guard let user = userManager.currentUser else {
            errorMessage = "유저 정보를 불러올 수 없습니다."
            return
        }

        do {
            // Sound 전체 가져오기
            let soundsSnapshot = try await Firestore.firestore()
                .collection("Sound")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            let allSounds = try soundsSnapshot.documents.compactMap {
                try $0.data(as: Sound.self)
            }

            let ownedSounds = allSounds.filter { sound in
                guard let id = sound.id else { return false }
                return user.soundEffects.contains(id)
            }
            let notOwnedSounds = allSounds.filter { sound in
                guard let id = sound.id else { return false }
                return !user.soundEffects.contains(id)
            }

            availableSounds = ownedSounds + notOwnedSounds

            // Particle 전체 가져오기
            let particlesSnapshot = try await Firestore.firestore()
                .collection("Particle")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            let allParticles = try particlesSnapshot.documents.compactMap {
                try $0.data(as: Particle.self)
            }

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

    // MARK: - Firebase Frames 가져오기
    func fetchFrames() async {
        do {
            let framesSnapshot = try await Firestore.firestore()
                .collection("Template")
                .document("Polaroid")
                .collection("Frames")
                .getDocuments()

            availableFrames = try framesSnapshot.documents.compactMap {
                try $0.data(as: Frame.self)
            }

            // 첫 번째 프레임을 기본 선택
            if let firstFrame = availableFrames.first {
                selectedFrame = firstFrame
            }

        } catch {
            errorMessage = "프레임 목록을 불러오는데 실패했습니다."
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
    /// 모드 변경 시 프레임 → 다른 모드로 전환되면 사진과 프레임 합성
    func onModeChanged(from oldMode: CustomizingMode, to newMode: CustomizingMode) {
        if oldMode == .frame && newMode != .frame {
            Task {
                await composePhotoWithFrame()
            }
        }
    }

    /// 다음 화면으로 이동하기 전 사진과 프레임 합성
    func beforeNavigateToNext() {
        Task {
            await composePhotoWithFrame()
        }
    }

    // MARK: - Customizing Modes
    var availableCustomizingModes: [CustomizingMode] {
        [.frame, .effect]
    }

    // MARK: - View Providers
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
        case .frame:
            return AnyView(FramePreviewView(viewModel: self, onSceneReady: onSceneReady))
        default:
            return AnyView(EmptyView())
        }
    }

    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(EffectSelectorView(viewModel: self, cartItems: cartItems))
        case .frame:
            return AnyView(FrameSelectorView(viewModel: self))
        default:
            return AnyView(EmptyView())
        }
    }

    func bottomViewHeightRatio(for mode: CustomizingMode) -> CGFloat {
        switch mode {
        case .frame:
            return 0.25  // 프레임 모드는 더 낮은 높이
        case .effect:
            return 0.35  // 이펙트 모드는 기본 높이
        default:
            return 0.35
        }
    }

    // MARK: - Reset
    func resetCustomizingData() {
        selectedSound = nil
        selectedParticle = nil
        customSoundURL = nil
        soundId = "none"
        particleId = "none"
        downloadingItemIds.removeAll()
        downloadProgress.removeAll()
        selectedFrame = nil
        selectedPhotoImage = nil
        photoScale = 1.0
        photoRotation = .zero
        photoOffset = .zero
        bodyImage = nil
        availableFrames.removeAll()
        isComposingPhoto = false
    }

    func resetInfoData() {
        nameText = ""
        memoText = ""
        selectedTags = []
    }

    func resetAll() {
        resetCustomizingData()
        resetInfoData()
    }
}
