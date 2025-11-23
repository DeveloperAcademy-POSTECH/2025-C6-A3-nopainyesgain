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
    var inputText: String = "텍스트를 입력해주세요"
    var selectedTextColor: Color = .black
    var maxTextLength: Int = 20
    
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
    var chainLength: Int { 5 }
    
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
        inputText = "텍스트를 입력해주세요"
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
