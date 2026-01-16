//
//  CollectionViewModel.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore
import SpriteKit

@Observable
class CollectionViewModel {
    
    // MARK: - 데이터
    var keyring: [Keyring] = []
    var tags: [String] = [] // 태그
    
    // MARK: - 공통 상태
    var isLoading = false
    var selectedSort: String = "최신순" // 기본값
    var maxKeyringCount: Int = 100 // 기본값
    var coin: Int = 0
    var copyVoucher: Int = 0
    var selectedKeyrings: [Keyring] = []
    var hasNetworkError: Bool = false
    
    // Firestore 문서 ID 매핑: 로컬 Keyring(UUID) -> Firestore 문서 ID(String)
    var keyringDocumentIdByLocalId: [UUID: String] = [:]

    // MARK: - Shared Data
    let dataManager = WorkshopDataManager.shared

    // MARK: - Computed Properties
    // 카테고리 목록 (전체 포함)
    var categories: [String] {
        getCategories()
    }

    // MARK: - 초기화
    init() {}

    // MARK: - Data Loading
    /// 배경 및 카라비너 데이터 로드 (캐싱된 데이터 활용)
    func loadBackgroundsAndCarabiners() async {
        await dataManager.fetchBackgroundsIfNeeded()
        await dataManager.fetchCarabinersIfNeeded()
    }

    /// 네트워크 에러 후 재시도
    func retryFetchData(userId: String) async {
        guard NetworkManager.shared.isConnected else { return }
        hasNetworkError = false

        await withCheckedContinuation { continuation in
            fetchUserCollectionData(uid: userId) { success in
                if success {
                    self.fetchUserKeyrings(uid: userId) { _ in
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

