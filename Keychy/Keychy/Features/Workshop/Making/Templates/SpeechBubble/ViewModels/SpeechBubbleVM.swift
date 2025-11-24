//
//  SpeechBubbleVM.swift
//  Keychy
//
//  Created by 길지훈 on 11/23/25.
//

import SwiftUI
import Combine
import FirebaseFirestore

@Observable
class SpeechBubbleVM: KeyringViewModelProtocol {
    // MARK: - Template Data
    var template: KeyringTemplate?
    var isLoadingTemplate = false
    
    // MARK: - Effect Data
    var availableSounds: [Sound] = []
    var availableParticles: [Particle] = []
    var selectedSound: Sound? = nil
    var selectedParticle: Particle? = nil
    var customSoundURL: URL? = nil
    var downloadingItemIds: Set<String> = []
    var downloadProgress: [String: Double] = [:]
    var soundId: String = "none"
    var particleId: String = "none"
    let effectSubject = PassthroughSubject<(soundId: String, particleId: String, type: KeyringUpdateType), Never>()
    
    // MARK: - Frame Data
    var availableFrames: [Frame] = []
    var selectedFrame: Frame? = nil
    
    // MARK: - Text Data
    var inputText: String = ""
    var selectedTextColor: Color = .black

    /// 현재 선택된 프레임 타입별 줄당 최대 글자 수
    var maxCharsPerLine: Int {
        guard let frameType = selectedFrame?.type else { return 10 }

        switch frameType {
        case "A": return 5   // A형: 5자×3줄
        case "B": return 11  // B형: 11자×1줄
        case "C": return 2   // C형: 2자×2줄
        default: return 10
        }
    }

    /// 현재 선택된 프레임 타입별 최대 줄 수
    var maxLines: Int {
        guard let frameType = selectedFrame?.type else { return 2 }

        switch frameType {
        case "A": return 3  // A형: 5자×3줄
        case "B": return 1  // B형: 11자×1줄
        case "C": return 2  // C형: 2자×2줄
        default: return 2
        }
    }
    
    // MARK: - Body Image
    var bodyImage: UIImage? = nil
    var hookOffsetY: CGFloat = 0.0
    var isComposingText: Bool = false
    var isComposing: Bool { isComposingText }
    
    // MARK: - Info Data
    var nameText: String = ""
    var maxTextCount: Int = 10
    var memoText: String = ""
    var maxMemoCount: Int = 500
    var selectedTags: [String] = []
    var createdAt: Date = Date()
    
    // MARK: - Dependencies
    var userManager: UserManager
    var errorMessage: String?
    
    // MARK: - Template Info
    var templateId: String { template?.id ?? "SpeechBubble" }
    var chainLength: Int { template?.chainLength ?? 3 }
    
    // MARK: - Customizing Modes
    var availableCustomizingModes: [CustomizingMode] { [.frame, .effect] }
    
    // MARK: - 초기화
    init(userManager: UserManager = UserManager.shared) {
        self.userManager = userManager
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
        inputText = ""
        selectedTextColor = .black
        bodyImage = nil
        availableFrames.removeAll()
        isComposingText = false
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
