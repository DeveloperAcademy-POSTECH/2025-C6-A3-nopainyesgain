//
//  CollectionViewModel.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import Foundation
import FirebaseStorage
import SpriteKit

@Observable
class CollectionViewModel {
    
    // MARK: - 프로퍼티
    var isLoading = false
    var keyring: [Keyring] = [] // 키링
    var tags: [String] = [] // 태그
    var selectedSort: String = "최신순" // 기본값
    var maxKeyringCount: Int = 100 // 기본값
    var coin: Int = 0
    var selectedKeyrings: [Keyring] = []
    
    // MARK: - 초기화
    init() {}
    // 키링 뭉치 관련
    var maxBundleNameCount: Int = 9
    var selectedKeyringsForBundle: [Int: Keyring] = [:] // 번들 생성용 선택된 키링들
    var bundlePreviewScene: CarabinerScene?
    
    // Firestore에서 로드되는 실제 뭉치 목록 (초기 빈 배열)
    var bundles: [KeyringBundle] = []
    var sortedBundles: [KeyringBundle] {
        bundles.sorted { a, b in
            // 메인 뭉치는 항상 첫 번째
            if a.isMain != b.isMain {
                return a.isMain
            }
            return a.createdAt > b.createdAt
        }
    }
    var selectedBundle: KeyringBundle?
    
    // MARK: - Shared Data Manager
    private let dataManager = WorkshopDataManager.shared

    // MARK: - 배경 및 카라비너 데이터 (WorkshopDataManager에서 가져옴)
    var backgrounds: [Background] { dataManager.backgrounds }
    var selectedBackground: Background?

    var carabiners: [Carabiner] { dataManager.carabiners }
    var selectedCarabiner: Carabiner?

    // MARK: - Data Loading
    /// 배경 및 카라비너 데이터 로드 (캐싱된 데이터 활용)
    func loadBackgroundsAndCarabiners() async {
        await dataManager.fetchBackgroundsIfNeeded()
        await dataManager.fetchCarabinersIfNeeded()
    }
}

