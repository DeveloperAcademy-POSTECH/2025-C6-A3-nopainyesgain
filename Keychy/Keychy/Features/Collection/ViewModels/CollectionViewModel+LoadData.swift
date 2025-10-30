//
//  CollectionViewModel+LoadData.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

extension CollectionViewModel {
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    // MARK: - Firebase에서 사용자의 모든 키링 로드
    func fetchUserKeyrings(uid: String, completion: @escaping (Bool) -> Void) {
        print("사용자 키링 로드 시작 - UID: \(uid)")
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
                
                print("User 문서에서 \(keyringIds.count)개의 키링 ID 발견")
                
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
        
        print("\(batches.count)개의 배치로 나눠서 처리")
        
        var allKeyrings: [Keyring] = []
        let dispatchGroup = DispatchGroup()
        
        for (index, batch) in batches.enumerated() {
            dispatchGroup.enter()
            
            print("배치 \(index + 1)/\(batches.count) 로드 중... (\(batch.count)개)")
            
            db.collection("Keyring")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Keyring 배치 \(index + 1) 로드 에러: \(error.localizedDescription)")
                        return
                    }
                    
                    let keyrings = snapshot?.documents.compactMap { document -> Keyring? in
                        let documentData = document.data()
                        
                        let keyring = Keyring(documentId: document.documentID, data: documentData)
                        
                        return keyring
                    } ?? []
                    
                    print("배치 \(index + 1) 로드 완료: \(keyrings.count)개")
                    allKeyrings.append(contentsOf: keyrings)
                }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.keyring = allKeyrings
            print("전체 키링 로드 완료: \(allKeyrings.count)개")
            print("로드된 키링 목록:")
            for (index, keyring) in allKeyrings.enumerated() {
                print("   \(index + 1). \(keyring.name)")
            }
            
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
            chainLength: chainLength
        )
        
        let keyringData = newKeyring.toDictionary()
        
        // Keyring 컬렉션에 새 키링 추가
        let docRef = db.collection("Keyring").document()
        
        print("Firestore에 키링 저장 중... - ID: \(docRef.documentID)")
        
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
    

}
