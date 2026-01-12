//
//  CollectionViewModel+LoadData.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import SpriteKit

extension CollectionViewModel {
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    // MARK: - Firebase에서 사용자의 모든 키링 로드
    func fetchUserKeyrings(uid: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // User 문서에서 보유한 키링 ID 목록 가져오기
        db.collection("User")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    print("User 문서 로드 에러: \(error.localizedDescription)")
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("User 문서 데이터가 없습니다")
                    self.keyring = []
                    self.isLoading = false
                    completion(true)
                    return
                }
                
                // 보유한 키링 없음
                guard let keyringIds = data["keyrings"] as? [String] else {
                    print("보유한 키링 없음")
                    self.keyring = []
                    self.isLoading = false
                    completion(true)
                    return
                }
                
                if keyringIds.isEmpty {
                    print("키링 ID 배열이 비어있음")
                    self.keyring = []
                    self.isLoading = false
                    completion(true)
                    return
                }
                
                // Keyring 컬렉션에서 해당 ID들의 키링 데이터 가져오기
                self.loadKeyringsByIds(keyringIds: keyringIds) { success in
                    self.isLoading = false
                    if success {
                        self.applySorting() // 자동 최신순 정렬 적용
                    }
                    completion(success)
                }
            }
    }
    
    // MARK: - 키링 ID 배열로 키링 데이터 로드
    private func loadKeyringsByIds(keyringIds: [String], completion: @escaping (Bool) -> Void) {
        print("키링 데이터 로드 시작: \(keyringIds.count)개")
        
        let batchSize = 10
        let batches = stride(from: 0, to: keyringIds.count, by: batchSize).map {
            Array(keyringIds[$0..<min($0 + batchSize, keyringIds.count)])
        }
        
        var allKeyrings: [Keyring] = []
        let dispatchGroup = DispatchGroup()
        
        for (index, batch) in batches.enumerated() {
            dispatchGroup.enter()
            
            db.collection("Keyring")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments { [weak self] snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Keyring 배치 \(index + 1) 로드 에러: \(error.localizedDescription)")
                        return
                    }
                    
                    let keyrings = snapshot?.documents.compactMap { document -> Keyring? in
                        let documentData = document.data()
                        let firestoreDocId = document.documentID
                        
                        let keyring = Keyring(documentId: firestoreDocId, data: documentData)
                        
                        self.keyringDocumentIdByLocalId[keyring?.id ?? UUID()] = firestoreDocId
                        
                        return keyring
                    } ?? []
                    
                    allKeyrings.append(contentsOf: keyrings)
                }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.keyring = allKeyrings
            
            completion(true)
        }
    }

    // MARK: - Firebase에서 컬렉션에 사용되는 사용자의 정보 로드
    func fetchUserCollectionData(uid: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        db.collection("User")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    print("User 문서 로드 에러: \(error.localizedDescription)")
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("User 문서 데이터가 없습니다")
                    self.keyring = []
                    self.isLoading = false
                    completion(true)
                    return
                }
                
                // 태그 가져오기
                if let categories = data["tags"] as? [String] {
                    self.tags = categories
                } else {
                    print("등록된 태그 없음")
                    self.tags = []
                }
                
                // 보관함 한계 수치 가져오기
                if let maxCount = data["maxKeyringCount"] as? Int {
                    self.maxKeyringCount = maxCount
                }
                
                // 재화 가져오기
                if let coin = data["coin"] as? Int {
                    self.coin = coin
                }
                
                // 복사권 가져오기
                if let copyVoucher = data["copyVoucher"] as? Int {
                    self.copyVoucher = copyVoucher
                }
                
                completion(true)

            }
    }
    
    
    // MARK: - 새 키링 생성 및 User에 추가
    func createKeyring(
        uid: String,
        name: String,
        bodyImage: String,
        soundId: String,
        particleId: String,
        memo: String?,
        tags: [String],
        selectedTemplate: String,
        selectedRing: String,
        selectedChain: String,
        chainLength: Int,
        isNew: Bool,
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("새 키링 생성 시작 - 이름: \(name)")
        
        let newKeyring = Keyring(
            name: name,
            bodyImage: bodyImage,
            soundId: soundId,
            particleId: particleId,
            memo: memo,
            tags: tags,
            createdAt: Date(),
            authorId: uid,
            selectedTemplate: selectedTemplate,
            selectedRing: selectedRing,
            selectedChain: selectedChain,
            chainLength: chainLength,
            isNew: isNew
        )
        
        let keyringData = newKeyring.toDictionary()
        
        // Keyring 컬렉션에 새 키링 추가
        let docRef = db.collection("Keyring").document()
        
        docRef.setData(keyringData) { [weak self] error in
            if let error = error {
                print("키링 생성 에러: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            let keyringId = docRef.documentID
            print("Firestore에 키링 저장 완료 - ID: \(keyringId)")
            
            // User 문서의 keyrings 배열에 ID 추가
            self?.addKeyringToUser(uid: uid, keyringId: keyringId) { success in
                if success {
                    print("키링 생성 및 User에 추가 완료: \(name)")
                    
                    // 로컬 배열에도 추가
                    let mutableKeyring = newKeyring
                    self?.keyring.append(mutableKeyring)
                    
                    completion(true, keyringId)
                } else {
                    completion(false, nil)
                }
            }
        }
    }
    
    // MARK: - User의 keyrings 배열에 키링 ID 추가
    private func addKeyringToUser(uid: String, keyringId: String, completion: @escaping (Bool) -> Void) {
        print("User 문서에 키링 ID 추가 중... - UID: \(uid), KeyringID: \(keyringId)")
        
        db.collection("User")
            .document(uid)
            .updateData([
                "keyrings": FieldValue.arrayUnion([keyringId])
            ]) { error in
                if let error = error {
                    print("User 키링 배열 업데이트 에러: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("User 키링 배열 업데이트 완료")
                    completion(true)
                }
            }
    }
    
    // MARK: - 단일 키링 ID로 키링 데이터 로드
    func fetchKeyringById(keyringId: String, completion: @escaping (Keyring?) -> Void) {
        print("키링 데이터 로드 시작 - ID: \(keyringId)")
        
        db.collection("Keyring")
            .document(keyringId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("키링 로드 에러: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot,
                      document.exists,
                      let data = document.data() else {
                    print("키링 문서가 존재하지 않습니다")
                    completion(nil)
                    return
                }
                
                let keyring = Keyring(documentId: keyringId, data: data)
                print("키링 로드 완료: \(keyring?.name ?? "이름 없음")")
                completion(keyring)
            }
    }
    
    // MARK: - 유저 닉네임 가져오기
    func fetchUserName(userId: String, completion: @escaping (String) -> Void) {
        db.collection("User")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("작성자 정보 로드 에러: \(error.localizedDescription)")
                    completion("알 수 없음")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let nickname = data["nickname"] as? String else {
                    completion("알 수 없음")
                    return
                }
                
                completion(nickname)
            }
    }
    
    // MARK: - 인벤 확장
    func purchaseInventoryExpansion(userManager: UserManager, expansionCost: Int = 100) async -> PurchaseResult {
        guard let userId = userManager.currentUser?.id,
              let userCoins = userManager.currentUser?.coin else {
            return .failed("사용자 정보를 찾을 수 없습니다")
        }
        
        // 코인 부족 시
        guard userCoins >= expansionCost else {
            return .insufficientCoins
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("User").document(userId)
        
        do {
            let snapshot = try await userRef.getDocument()
            guard let data = snapshot.data() else {
                return .failed("사용자 정보를 찾을 수 없습니다")
            }
            
            let currentCoin = data["coin"] as? Int ?? 0
            let currentMaxCount = data["maxKeyringCount"] as? Int ?? 0
            
            guard currentCoin >= expansionCost else {
                return .insufficientCoins
            }
            
            // Firestore 업데이트
            try await userRef.updateData([
                "coin": currentCoin - expansionCost,
                "maxKeyringCount": currentMaxCount + 10
            ])
            
            // 로컬 UserManager 갱신
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                userManager.loadUserInfo(uid: userId) { _ in
                    continuation.resume()
                }
            }
            
            return .success
            
        } catch {
            print("인벤토리 확장 실패: \(error.localizedDescription)")
            return .failed("인벤토리 확장 처리 중 오류가 발생했습니다")
        }
    }
    
    // MARK: - 키링 데이터 로딩 (공통 함수)
    
    func prefetchKeyringImage(keyring: Keyring) async {
        guard let keyringID = keyring.documentId,
              !KeyringImageCache.shared.exists(for: keyringID, type: .thumbnail) else {
            return
        }
        
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)

        await withCheckedContinuation { continuation in
            var loadingCompleted = false

            let scene = KeyringCellScene(
                ringType: ringType,
                chainType: chainType,
                bodyImage: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
                targetSize: CGSize(width: 175, height: 233),
                customBackgroundColor: .clear,
                zoomScale: 2.0,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.scaleMode = .aspectFill

            let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
            view.allowsTransparency = true
            view.presentScene(scene)

            Task {
                var waitTime = 0.0
                while !loadingCompleted && waitTime < 5.0 {
                    try? await Task.sleep(for: .seconds(0.1))
                    waitTime += 0.1
                }

                guard loadingCompleted else {
                    print("[Prefetch] 타임아웃: \(keyring.name)")
                    continuation.resume()
                    return
                }

                try? await Task.sleep(for: .seconds(0.2))

                if let pngData = await scene.captureToPNG(),
                   !pngData.isEmpty,
                   UIImage(data: pngData) != nil {
                    KeyringImageCache.shared.save(pngData: pngData, for: keyringID, type: .thumbnail)
                    
                    if !keyring.isPackaged && !keyring.isPublished {
                        KeyringImageCache.shared.syncKeyring(
                            id: keyringID,
                            name: keyring.name,
                            imageData: pngData
                        )
                    }
                }

                continuation.resume()
            }
        }
    }
}
