//
//  WorkshopDataManager.swift
//  Keychy
//
//  Created by Rundo on 11/3/25.
//

import SwiftUI
import FirebaseFirestore
import Nuke

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
    var workshopBannerURL: URL?
    var workshopThumbnailURL: URL?
    var workshopThumbnailImage: UIImage? // prefetch한 썸네일 이미지

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
        templates = await fetchItems(collection: "Template")
        updateLastFetched(for: "Template")
    }

    /// 배경 데이터 가져오기
    func fetchBackgroundsIfNeeded() async {
        if isCacheValid(for: "Background") && !backgrounds.isEmpty {
            return
        }
        backgrounds = await fetchItems(collection: "Background")
        updateLastFetched(for: "Background")
    }

    /// 카라비너 데이터 가져오기
    func fetchCarabinersIfNeeded() async {
        if isCacheValid(for: "Carabiner") && !carabiners.isEmpty {
            return
        }
        carabiners = await fetchItems(collection: "Carabiner")
        updateLastFetched(for: "Carabiner")
    }

    /// 파티클 데이터 가져오기
    func fetchParticlesIfNeeded() async {
        if isCacheValid(for: "Particle") && !particles.isEmpty {
            return
        }
        particles = await fetchItems(collection: "Particle")
        updateLastFetched(for: "Particle")
    }

    /// 사운드 데이터 가져오기
    func fetchSoundsIfNeeded() async {
        if isCacheValid(for: "Sound") && !sounds.isEmpty {
            return
        }
        sounds = await fetchItems(collection: "Sound")
        updateLastFetched(for: "Sound")
    }
    
    /// 워크샵 배너 가져오기
    func fetchWorkshopBanner() async {
        guard
            let snapshot = try? await Firestore.firestore()
                .collection("WorkshopBanner")
                .document("default")
                .getDocument(),
            let data = snapshot.data()
        else {
            return
        }

        await MainActor.run {
            // GIF URL
            if let urlString = data["gif"] as? String,
               let url = URL(string: urlString) {
                workshopBannerURL = url
            }

            // 썸네일 URL
            if let thumbnailString = data["thumbnail"] as? String,
               let thumbnailURL = URL(string: thumbnailString) {
                workshopThumbnailURL = thumbnailURL
            }
        }

        // 썸네일 이미지 즉시 로드 (UIImage로 저장)
        if let thumbnailURL = workshopThumbnailURL {
            if let response = try? await ImagePipeline.shared.image(for: thumbnailURL) {
                await MainActor.run {
                    workshopThumbnailImage = response
                }
            }
        }

        // GIF는 prefetch만 (애니메이션이라 UIImage로 저장 불가)
        if let gifURL = workshopBannerURL {
            let prefetcher = ImagePrefetcher()
            prefetcher.startPrefetching(with: [gifURL])
        }
    }


    /// 캐시를 강제로 무효화하고 다시 가져오기
    func forceRefresh() async {
        lastFetchedDate.removeAll()
        await fetchAllDataIfNeeded()
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

            // isActive 필터 적용 (모든 컬렉션)
            #if DEBUG
            let snapshot = try await collectionRef.getDocuments()
            #else
            let snapshot = try await collectionRef.whereField("isActive", isEqualTo: true).getDocuments()
            #endif


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
