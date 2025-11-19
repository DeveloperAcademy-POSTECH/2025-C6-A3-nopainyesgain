//
//  AcrylicPhotoVM.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/17/25.
// 설명: 아크릴 포토 템플릿 뷰모델
// 이미지 처리(크롭 + 누끼) + 템플릿 데이터 관리

import SwiftUI
import PhotosUI
import Vision
import Combine
import FirebaseFirestore

enum KeyringUpdateType {
    case sound
    case particle
}

@Observable
class AcrylicPhotoVM: KeyringViewModelProtocol {
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

    // MARK: - 이미지 선택 관련
    var selectedImage: UIImage?
    var fixedImage: UIImage?
    var isProcessing: Bool = false
    var errorMessage: String?

    // MARK: - 크롭 관련
    var cropArea: CGRect = .zero
    var imageViewSize: CGSize = .zero
    var initialCropArea: CGRect?
    var draggedCorner: CropCorner?
    var hasCropAreaBeenSet: Bool = false

    // MARK: - 크롭 결과
    var croppedImage: UIImage = UIImage()
    var removedBackgroundImage: UIImage = UIImage()
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0  // addAcrylicStroke에서 계산한 값

    /// 템플릿 ID
    var templateId: String {
        template?.id ?? "AcrylicPhoto"
    }

    let minimumCropSize: CGSize = CGSize(width: 100, height: 100)

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

    // MARK: - 이미지 데이터 초기화
    func resetImageData() {
        selectedImage = nil
        fixedImage = nil
        cropArea = .zero
        hasCropAreaBeenSet = false
        croppedImage = UIImage()
        removedBackgroundImage = UIImage()
        bodyImage = nil
        errorMessage = nil
    }

    // MARK: - 편집 데이터 초기화
    /// 편집뷰에서 뒤로가기 시 호출
    /// 누끼 제거된 이미지를 초기화
    func resetEditData() {
        removedBackgroundImage = UIImage()
        bodyImage = nil
    }

    // MARK: - 완전 초기화
    /// 이미지 선택이 있는 템플릿이므로 resetImageData()도 호출
    func resetAll() {
        resetImageData()
        resetCustomizingData()
        resetInfoData()
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

        /// defer 키워드 -> 함수가 끝날 때 무조건 실행되는 코드
        defer { isLoadingTemplate = false }

        do {
            let document = try await Firestore.firestore()
                .collection("Template")
                .document("AcrylicPhoto")
                .getDocument()

            template = try document.data(as: KeyringTemplate.self)

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
    /// 이펙트 정렬 우선순위 계산
    /// 다운로드 여부 중심 정렬: 무료 다운로드 → 유료 다운로드 → 무료 미다운로드 → 유료 미다운로드
    private func getSortPriority(isFree: Bool, isDownloaded: Bool) -> Int {
        if isFree && isDownloaded { return 1 }
        if !isFree && isDownloaded { return 2 }
        if isFree && !isDownloaded { return 3 }
        if !isFree && !isDownloaded { return 4 }
        return 99
    }

    // MARK: - Customizing Modes
    /// 커스터마이징 모드 (아크릴 포토는 이펙트만 지원)
    var availableCustomizingModes: [CustomizingMode] {
        [.effect]
    }
}
