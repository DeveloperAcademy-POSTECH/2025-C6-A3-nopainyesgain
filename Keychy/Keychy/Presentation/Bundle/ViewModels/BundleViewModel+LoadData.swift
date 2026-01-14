//
//  BundleViewModel+LoadData.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

import FirebaseFirestore

extension BundleViewModel {
    //MARK: - Firebase에서 사용자의 모든 뭉치 로드
    func fetchAllBundles(uid: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        db.collection("KeyringBundle")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                defer { self.isLoading = false }
                
                if let error = error {
                    print("뭉치 로드 에러: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("뭉치 문서가 없습니다.")
                    self.bundles = []
                    completion(true)
                    return
                }
                
                let loadedBundles: [KeyringBundle] = documents.compactMap { doc in
                    KeyringBundle(documentId: doc.documentID, data: doc.data())
                }
                
                // 뷰모델 번들에 저장 (정렬은 sortedBundles에서 처리)
                self.bundles = loadedBundles
                completion(true)
            }
    }
    
    // MARK: - 전체 배경 로드 + 소유 여부 주석 (dataManager 활용)
    func fetchAllBackgrounds(completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            // dataManager를 통해 캐싱된 데이터 활용
            await dataManager.fetchBackgroundsIfNeeded()
            
            // dataManager에서 이미 로드된 데이터 가져오기
            let items = backgrounds // dataManager.backgrounds
            let ownedIds = UserManager.shared.currentUser?.backgrounds ?? []
            let decorated = items.map { bg in
                BackgroundViewData(background: bg, isOwned: ownedIds.contains(bg.id ?? ""))
            }
            
            await MainActor.run {
                self.backgroundViewData = decorated
                self.isLoading = false
                completion(true)
            }
        }
    }
    
    // MARK: - 전체 카라비너 로드 + 소유 여부 주석 (dataManager 활용)
    func fetchAllCarabiners(completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            // dataManager를 통해 캐싱된 데이터 활용
            await dataManager.fetchCarabinersIfNeeded()
            
            // dataManager에서 이미 로드된 데이터 가져오기
            let items = carabiners // dataManager.carabiners
            let ownedIds = UserManager.shared.currentUser?.carabiners ?? []
            let decorated = items.map { cb in
                CarabinerViewData(carabiner: cb, isOwned: ownedIds.contains(cb.id ?? ""))
            }
            
            await MainActor.run {
                self.carabinerViewData = decorated
                self.isLoading = false
                completion(true)
            }
        }
        // 카라비너는 기본 카라비너 자동 선택 됨
        selectedCarabiner = carabiners.first
    }
    
    /// Firestore에서 키링 정보를 가져옴
    func fetchKeyringInfo(keyringId: String) async -> KeyringInfo? {
        do {
            let document = try await db.collection("Keyring").document(keyringId).getDocument()

            guard let data = document.data(),
                  let bodyImage = data["bodyImage"] as? String,
                  let soundId = data["soundId"] as? String,
                  let particleId = data["particleId"] as? String else {
                return nil
            }

            let hookOffsetY = data["hookOffsetY"] as? CGFloat ?? 0.0
            let chainLength = data["chainLength"] as? Int ?? 5
            let selectedTemplate = data["selectedTemplate"] as? String

            return KeyringInfo(
                id: keyringId,
                bodyImage: bodyImage,
                selectedTemplate: selectedTemplate,
                soundId: soundId,
                particleId: particleId,
                hookOffsetY: hookOffsetY,
                chainLength: chainLength
            )
        } catch {
            return nil
        }
    }
}
