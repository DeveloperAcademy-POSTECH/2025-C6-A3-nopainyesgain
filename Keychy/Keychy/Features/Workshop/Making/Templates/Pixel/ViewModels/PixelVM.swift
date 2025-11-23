//
//  PixelKeyringVM.swift
//  Keychy
//
//  Created by 길지훈 on 11/22/25.
//

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class PixelVM: KeyringViewModelProtocol {
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

    // MARK: - Pixel Grid Data
    /// 15x15 픽셀 그리드 (각 셀의 색상)
    var pixelGrid: [[Color]] = Array(repeating: Array(repeating: .clear, count: 15), count: 15)

    /// Undo/Redo 스택
    var undoStack: [[[Color]]] = []
    var redoStack: [[[Color]]] = []

    /// 현재 그리기 모드 (draw or eraser)
    var isDrawMode: Bool = true

    /// 현재 선택된 색상
    var selectedColor: Color = .black

    /// 바디 이미지 (픽셀 그리드를 이미지로 변환한 결과)
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0

    /// 체인 길이 (Pixel은 1)
    var chainLength: Int { 3 }

    /// 템플릿 ID
    var templateId: String {
        template?.id ?? "PixelKeyring"
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

    // MARK: - Pixel Drawing Methods

    /// 픽셀 색칠하기
    func paintPixel(row: Int, col: Int) {
        guard row >= 0, row < 15, col >= 0, col < 15 else { return }

        let newColor = isDrawMode ? selectedColor : .clear

        // 이미 같은 색이면 무시
        if pixelGrid[row][col] == newColor { return }

        // Undo 스택에 현재 상태 저장
        saveToUndoStack()

        // 색상 변경
        pixelGrid[row][col] = newColor

        // Redo 스택 초기화 (새로운 작업 시)
        redoStack.removeAll()
    }

    /// Undo 스택에 현재 상태 저장
    private func saveToUndoStack() {
        undoStack.append(pixelGrid)

        // 최대 50개까지만 저장
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }

    /// Undo
    func undo() {
        guard !undoStack.isEmpty else { return }

        // 현재 상태를 Redo 스택에 저장
        redoStack.append(pixelGrid)

        // Undo 스택에서 이전 상태 복원
        pixelGrid = undoStack.removeLast()
    }

    /// Redo
    func redo() {
        guard !redoStack.isEmpty else { return }

        // 현재 상태를 Undo 스택에 저장
        undoStack.append(pixelGrid)

        // Redo 스택에서 다음 상태 복원
        pixelGrid = redoStack.removeLast()
    }

    /// 전체 초기화
    func clearGrid() {
        saveToUndoStack()
        pixelGrid = Array(repeating: Array(repeating: .clear, count: 15), count: 15)
        redoStack.removeAll()
    }

    // MARK: - 픽셀 그리드 데이터 초기화
    func resetPixelData() {
        pixelGrid = Array(repeating: Array(repeating: .clear, count: 15), count: 15)
        undoStack.removeAll()
        redoStack.removeAll()
        bodyImage = nil
        isDrawMode = true
        selectedColor = .black
    }

    // MARK: - 완전 초기화
    func resetAll() {
        resetPixelData()
        resetCustomizingData()
        resetInfoData()
    }

    // MARK: - Firebase Template 가져오기
    func fetchTemplate() async {
        isLoadingTemplate = true
        defer { isLoadingTemplate = false }

        do {
            let document = try await Firestore.firestore()
                .collection("Template")
                .document("PixelKeyring")
                .getDocument()

            template = try document.data(as: KeyringTemplate.self)
        } catch {
            print("템플릿을 불러오는데 실패했습니다: \(error)")
        }
    }

    // MARK: - Firebase Effects 가져오기
    func fetchEffects() async {
        guard let user = userManager.currentUser else {
            print("유저 정보를 불러올 수 없습니다.")
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
            print("이펙트 목록을 불러오는데 실패했습니다: \(error)")
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
}
