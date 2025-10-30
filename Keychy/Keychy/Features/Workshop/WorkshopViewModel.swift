//
//  WorkshopViewModel.swift
//  Keychy
//
//  Created by rundo on 10/30/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Filter Types

enum TemplateFilterType: String, CaseIterable {
    case image = "이미지"
    case text = "텍스트"
    case drawing = "드로잉"
}

enum EffectFilterType: String, CaseIterable {
    case sound = "사운드"
    case particle = "파티클"
}

// CommonFilterType은 더 이상 사용하지 않음 - 동적 태그로 대체

// MARK: - WorkshopItem Protocol

/// 공방에서 판매되는 모든 아이템이 준수해야 하는 프로토콜
protocol WorkshopItem: Identifiable, Decodable {
    var id: String? { get }
    var name: String { get }
    var itemDescription: String { get }
    var thumbnailURL: String { get }
    var isFree: Bool { get }
    var workshopPrice: Int { get }
    var tags: [String] { get }
    var downloadCount: Int { get }
    var createdAt: Date { get }
}

// MARK: - Extensions

extension KeyringTemplate: WorkshopItem {
    var name: String { templateName }
    var itemDescription: String { description }
    var workshopPrice: Int { price ?? 0 }
}

extension Background: WorkshopItem {
    var name: String { backgroundName }
    var itemDescription: String { description }
    var thumbnailURL: String { backgroundImage }
    var workshopPrice: Int { price }
}

extension Carabiner: WorkshopItem {
    var name: String { carabinerName }
    var itemDescription: String { description }
    var thumbnailURL: String { carabinerImage }
    var workshopPrice: Int { price }
}

extension Particle: WorkshopItem {
    var name: String { particleName }
    var itemDescription: String { description }
    var thumbnailURL: String { thumbnail }
    var workshopPrice: Int { price }
}

extension Sound: WorkshopItem {
    var name: String { soundName }
    var itemDescription: String { description }
    var thumbnailURL: String { thumbnail }
    var workshopPrice: Int { price }
}

// MARK: - ViewModel

@MainActor
@Observable
class WorkshopViewModel {
    // MARK: - Published Properties
    var selectedCategory: String = "키링"
    var selectedTemplateFilter: TemplateFilterType? = nil
    var selectedCommonFilter: String? = nil
    var selectedEffectFilter: EffectFilterType? = nil
    var sortOrder: String = "최신순"
    var showFilterSheet: Bool = false
    var mainContentOffset: CGFloat = 0

    // 동적으로 추출된 태그 목록
    var availableBackgroundTags: [String] = []
    var availableCarabinerTags: [String] = []
    
    // Firebase 데이터 관련 상태 변수
    var templates: [KeyringTemplate] = []
    var backgrounds: [Background] = []
    var carabiners: [Carabiner] = []
    var particles: [Particle] = []
    var sounds: [Sound] = []
    
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // 보유한 아이템 목록
    var ownedTemplates: [KeyringTemplate] = []
    var ownedBackgrounds: [Background] = []
    var ownedCarabiners: [Carabiner] = []
    var ownedParticles: [Particle] = []
    var ownedSounds: [Sound] = []
    
    private var userManager: UserManager
    
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    // MARK: - Firebase Methods (통합)
    
    /// 모든 데이터 가져오기
    func fetchAllData() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        templates = await fetchItems(collection: "Template")
        backgrounds = await fetchItems(collection: "Background")
        carabiners = await fetchItems(collection: "Carabiner")
        particles = await fetchItems(collection: "Particle")
        sounds = await fetchItems(collection: "Sound")

        // 데이터를 가져온 후 사용 가능한 태그 추출
        extractAvailableTags()
    }

    /// 배경과 카라비너에서 사용 가능한 태그를 추출
    private func extractAvailableTags() {
        // 배경 태그 추출
        let backgroundTagSet = Set(backgrounds.flatMap { $0.tags })
        availableBackgroundTags = Array(backgroundTagSet).sorted()

        // 카라비너 태그 추출
        let carabinerTagSet = Set(carabiners.flatMap { $0.tags })
        availableCarabinerTags = Array(carabinerTagSet).sorted()
    }
    
    /// 통합된 아이템 가져오기 함수
    private func fetchItems<T: WorkshopItem>(collection: String) async -> [T] {
        do {
            let collectionRef = Firestore.firestore().collection(collection)
            let query: Query
            
            // Template 컬렉션인 경우에만 isActive 필터 적용
            if collection == "Template" {
                query = collectionRef.whereField("isActive", isEqualTo: true)
            } else {
                query = collectionRef
            }
            
            let snapshot = try await query.getDocuments()
            
            var items = try snapshot.documents.compactMap { document in
                try document.data(as: T.self)
            }
            items = sortItems(items)
            return items
        } catch {
            errorMessage = "\(collection) 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Sorting Methods (통합)
    
    /// 통합 정렬 함수
    private func sortItems<T: WorkshopItem>(_ items: [T]) -> [T] {
        var sortedItems = items
        switch sortOrder {
        case "최신순":
            sortedItems.sort { $0.createdAt > $1.createdAt }
        case "인기순":
            sortedItems.sort { $0.downloadCount > $1.downloadCount }
        default:
            break
        }
        return sortedItems
    }
    
    func applySorting() {
        templates = sortItems(templates)
        backgrounds = sortItems(backgrounds)
        carabiners = sortItems(carabiners)
        particles = sortItems(particles)
        sounds = sortItems(sounds)
    }
    
    // MARK: - Filtering Methods (통합)
    
    /// 통합 필터링 함수
    private func filterItems<T: WorkshopItem>(_ items: [T], commonFilter: String?) -> [T] {
        var result = items

        if let filter = commonFilter {
            result = result.filter { $0.tags.contains(filter) }
        }

        return result
    }
    
    /// 이펙트 필터링 (사운드 + 파티클 통합)
    var filteredEffects: [any WorkshopItem] {
        var result: [any WorkshopItem] = []
        
        switch selectedEffectFilter {
        case .sound:
            result = sounds
        case .particle:
            result = particles
        case nil:
            // 필터가 없으면 사운드와 파티클 모두 표시
            result = (sounds as [any WorkshopItem]) + (particles as [any WorkshopItem])
        }
        
        return result
    }
    
    /// 필터링된 템플릿 목록
    var filteredTemplates: [KeyringTemplate] {
        var result = templates
        
        if let filter = selectedTemplateFilter {
            switch filter {
            case .image:
                result = result.filter { $0.tags.contains("이미지형") }
            case .text:
                result = result.filter { $0.tags.contains("텍스트형") }
            case .drawing:
                result = result.filter { $0.tags.contains("드로잉형") }
            }
        }
        
        return result
    }
    
    var filteredBackgrounds: [Background] {
        filterItems(backgrounds, commonFilter: selectedCommonFilter)
    }
    
    var filteredCarabiners: [Carabiner] {
        filterItems(carabiners, commonFilter: selectedCommonFilter)
    }
    
    // MARK: - Owned Items Methods (통합)
    
    /// 사용자가 보유한 아이템 목록 로드
    func loadOwnedItems() async {
        guard let user = userManager.currentUser else { return }
        
        ownedTemplates = await loadOwnedItems(collection: "Template", ids: user.templates)
        ownedBackgrounds = await loadOwnedItems(collection: "Background", ids: user.backgrounds)
        ownedCarabiners = await loadOwnedItems(collection: "Carabiner", ids: user.carabiners)
        ownedParticles = await loadOwnedItems(collection: "Particle", ids: user.particleEffects)
        ownedSounds = await loadOwnedItems(collection: "Sound", ids: user.soundEffects)
    }
    
    /// 통합된 보유 아이템 로드 함수
    private func loadOwnedItems<T: WorkshopItem>(collection: String, ids: [String]) async -> [T] {
        guard !ids.isEmpty else { return [] }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection(collection)
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments()
            
            return try snapshot.documents.compactMap { try $0.data(as: T.self) }
        } catch {
            print("Failed to load owned \(collection): \(error)")
            return []
        }
    }
    
    /// 통합된 보유 여부 확인 함수
    private func isItemOwned<T: WorkshopItem>(_ item: T, userItems: [String]) -> Bool {
        guard let itemId = item.id else { return false }
        return userItems.contains(itemId)
    }
    
    func isTemplateOwned(_ template: KeyringTemplate) -> Bool {
        isItemOwned(template, userItems: userManager.currentUser?.templates ?? [])
    }
    
    func isBackgroundOwned(_ background: Background) -> Bool {
        isItemOwned(background, userItems: userManager.currentUser?.backgrounds ?? [])
    }
    
    func isCarabinerOwned(_ carabiner: Carabiner) -> Bool {
        isItemOwned(carabiner, userItems: userManager.currentUser?.carabiners ?? [])
    }
    
    func isParticleOwned(_ particle: Particle) -> Bool {
        isItemOwned(particle, userItems: userManager.currentUser?.particleEffects ?? [])
    }
    
    func isSoundOwned(_ sound: Sound) -> Bool {
        isItemOwned(sound, userItems: userManager.currentUser?.soundEffects ?? [])
    }
    
    /// 카테고리 변경 시 필터 초기화
    func resetFilters() {
        selectedTemplateFilter = nil
        selectedCommonFilter = nil
        selectedEffectFilter = nil
    }
}
