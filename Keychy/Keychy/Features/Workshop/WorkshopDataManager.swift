//
//  WorkshopDataManager.swift
//  Keychy
//
//  Created by Claude on 11/3/25.
//

import SwiftUI
import FirebaseFirestore

/// 공방(Workshop) 관련 데이터를 앱 전역에서 공유하고 캐싱하는 Manager
/// Singleton 패턴을 사용하여 Firestore 호출을 최소화하고 성능을 최적화
@MainActor
@Observable
class WorkshopDataManager {
    static let shared = WorkshopDataManager()

    // MARK: - Cached Data
    var templates: [KeyringTemplate] = []
    var backgrounds: [Background] = []
    var carabiners: [Carabiner] = []
    var particles: [Particle] = []
    var sounds: [Sound] = []

    // MARK: - Cache State
    private var lastFetchedDate: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5분

    var isLoading: Bool = false
    var errorMessage: String? = nil

    private init() {}

    // MARK: - Public Fetch Methods

    /// 모든 데이터를 가져옵니다 (캐시가 유효하면 기존 데이터 반환)
    func fetchAllDataIfNeeded() async {
        await fetchTemplatesIfNeeded()
        await fetchBackgroundsIfNeeded()
        await fetchCarabinersIfNeeded()
        await fetchParticlesIfNeeded()
        await fetchSoundsIfNeeded()
    }

    /// 템플릿 데이터 가져오기
    func fetchTemplatesIfNeeded() async {
        if isCacheValid(for: "Template") && !templates.isEmpty {
            return
        }
        let items: [KeyringTemplate] = await fetchItems(collection: "Template")
        self.templates = items
        updateLastFetched(for: "Template")
    }

    /// 배경 데이터 가져오기
    func fetchBackgroundsIfNeeded() async {
        if isCacheValid(for: "Background") && !backgrounds.isEmpty {
            return
        }
        let items: [Background] = await fetchItems(collection: "Background")
        self.backgrounds = items
        updateLastFetched(for: "Background")
    }

    /// 카라비너 데이터 가져오기
    func fetchCarabinersIfNeeded() async {
        if isCacheValid(for: "Carabiner") && !carabiners.isEmpty {
            return
        }
        let items: [Carabiner] = await fetchItems(collection: "Carabiner")
        self.carabiners = items
        updateLastFetched(for: "Carabiner")
    }

    /// 파티클 데이터 가져오기
    func fetchParticlesIfNeeded() async {
        if isCacheValid(for: "Particle") && !particles.isEmpty {
            return
        }
        let items: [Particle] = await fetchItems(collection: "Particle")
        self.particles = items
        updateLastFetched(for: "Particle")
    }

    /// 사운드 데이터 가져오기
    func fetchSoundsIfNeeded() async {
        if isCacheValid(for: "Sound") && !sounds.isEmpty {
            return
        }
        let items: [Sound] = await fetchItems(collection: "Sound")
        self.sounds = items
        updateLastFetched(for: "Sound")
    }

    // MARK: - Private Helper Methods

    /// 캐시가 유효한지 확인
    private func isCacheValid(for collection: String) -> Bool {
        guard let lastFetched = lastFetchedDate[collection] else {
            return false
        }
        return Date().timeIntervalSince(lastFetched) < cacheValidityDuration
    }

    /// 마지막 fetch 시간 업데이트
    private func updateLastFetched(for collection: String) {
        lastFetchedDate[collection] = Date()
    }

    /// Firestore에서 아이템 가져오기 (통합)
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

            let items = try snapshot.documents.compactMap { document in
                try document.data(as: T.self)
            }

            return items
        } catch {
            errorMessage = "\(collection) 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("WorkshopDataManager - fetchItems error: \(error)")
            return []
        }
    }
}
