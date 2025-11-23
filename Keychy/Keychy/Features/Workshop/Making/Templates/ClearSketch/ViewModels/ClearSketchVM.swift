//
//  ClearSketchVM.swift
//  Keychy
//
//  Created by Jini on 11/19/25.
//

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class ClearSketchVM: KeyringViewModelProtocol {
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
    
    // MARK: - Sketch Data
    /// 16x16 픽셀 그리드 (각 셀의 색상)
    var pixelGrid: [[Color]] = Array(repeating: Array(repeating: .clear, count: 16), count: 16)

    /// Undo/Redo 스택
    var undoStack: [[[Color]]] = []
    var redoStack: [[[Color]]] = []

    /// 현재 그리기 모드 (draw or eraser)
    var isDrawing: Bool = true
    var isEraser: Bool = false

    /// 현재 선택된 색상
    var selectedColor: Color = .black

    /// 바디 이미지 (픽셀 그리드를 이미지로 변환한 결과)
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0

    /// 템플릿 ID
    var templateId: String {
        template?.id ?? "ClearSketch"
    }
    
    var errorMessage: String?

    // MARK: - Drawing State (그리기 모드)
    var drawingPaths: [DrawingPath] = []
    var undoneDrawingPaths: [DrawingPath] = []
    var currentColor: Color = .black
    var currentLineWidth: CGFloat = 3.0
    
    // MARK: - Drawing Composition State
    var isComposingDrawing: Bool = false

    /// 프로토콜 준수: 합성 진행 중 여부
    var isComposing: Bool {
        isComposingDrawing
    }

    // MARK: - 정보 입력
    var nameText: String = ""
    var maxTextCount: Int = 10
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
                .document("ClearSketch")
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

            // 소유한 것 먼저, 그 다음 미소유
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

            // 소유한 것 먼저, 그 다음 미소유
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

    // MARK: - Customizing Modes
    var availableCustomizingModes: [CustomizingMode] {
        [.effect]
    }

    // MARK: - View Providers
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
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
        default:
            return AnyView(EmptyView())
        }
    }

    func bottomViewHeightRatio(for mode: CustomizingMode) -> CGFloat {
        switch mode {
        case .drawing:
            return 0.25  // 그리기 도구는 낮은 높이
        case .effect:
            return 0.35  // 이펙트 모드는 기본 높이
        default:
            return 0.35
        }
    }

    // MARK: - Reset Methods
    func resetCustomizingData() {
        selectedSound = nil
        selectedParticle = nil
        customSoundURL = nil
        soundId = "none"
        particleId = "none"
        downloadingItemIds.removeAll()
        downloadProgress.removeAll()
        
        // 그리기 관련 초기화
        drawingPaths.removeAll()
        currentColor = .black
        currentLineWidth = 3.0
        isDrawing = false
        bodyImage = nil
        isComposingDrawing = false
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

    // MARK: - 그리기 데이터 초기화 (추가 메서드)
    func resetImageData() {
        drawingPaths.removeAll()
        undoneDrawingPaths.removeAll()
        bodyImage = nil
        isDrawing = false
    }
    
    
}

// MARK: - DrawingPath 구조체 (필요시 추가)
struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
    var color: Color = .black
    var lineWidth: CGFloat = 3.0
    var isEraser: Bool = false
}
