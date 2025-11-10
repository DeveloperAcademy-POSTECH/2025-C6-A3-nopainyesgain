//
//  CollectionViewModel+Edit.swift
//  Keychy
//
//  Created by Jini on 11/6/25.
//

import SwiftUI
import FirebaseFirestore
import WidgetKit

extension CollectionViewModel {
    
    // MARK: - 키링 편집
    func updateKeyring(
        keyring: Keyring,
        name: String,
        memo: String,
        tags: [String],
        completion: @escaping (Bool) -> Void
    ) {
        guard let documentId = keyringDocumentIdByLocalId[keyring.id] else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        let updateData: [String: Any] = [
            "name": name,
            "memo": memo,
            "tags": tags
        ]
        
        
        db.collection("Keyring")
            .document(documentId)
            .updateData(updateData) { [weak self] error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                guard error == nil else { completion(false); return }

                if let index = self.keyring.firstIndex(where: { $0.id == keyring.id }) {
                    self.keyring[index].name = name
                    self.keyring[index].memo = memo
                    self.keyring[index].tags = tags

                    // 이름이 변경된 경우 App Group 메타데이터 업데이트
                    if keyring.name != name {
                        var keyrings = KeyringImageCache.shared.loadAvailableKeyrings()
                        if let keyringIndex = keyrings.firstIndex(where: { $0.id == documentId }) {
                            keyrings[keyringIndex] = AvailableKeyring(
                                id: documentId,
                                name: name,
                                imagePath: keyrings[keyringIndex].imagePath
                            )
                            KeyringImageCache.shared.saveAvailableKeyrings(keyrings)

                            // 위젯 타임라인 새로고침
                            WidgetCenter.shared.reloadTimelines(ofKind: "WidgetKeychy")
                        }
                    }
                }

                completion(true)
            }
    }
    
    // MARK: - 키링 삭제
    func deleteKeyring(
        uid: String,
        keyring: Keyring,
        completion: @escaping (Bool) -> Void
    ) {
        
        guard let documentId = keyringDocumentIdByLocalId[keyring.id] else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()

        // 1. Bundle 정보 조회
        db.collection("KeyringBundle")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    completion(false)
                    return
                }
                
                // 2. Batch 생성 - 모든 작업을 원자적으로 처리
                let batch = db.batch()
                
                // 2-1. Keyring 문서 삭제
                let keyringRef = db.collection("Keyring").document(documentId)
                batch.deleteDocument(keyringRef)
                
                // 2-2. User의 keyrings 배열에서 제거
                let userRef = db.collection("User").document(uid)
                batch.updateData([
                    "keyrings": FieldValue.arrayRemove([documentId])
                ], forDocument: userRef)
                
                // 2-3. Bundle에서 키링을 "none"으로 변경
                if let documents = snapshot?.documents, !documents.isEmpty {
                    for document in documents {
                        guard var keyrings = document.data()["keyrings"] as? [String] else {
                            continue
                        }
                        
                        var needsUpdate = false
                        
                        // 배열을 순회하면서 keyringId를 "none"으로 변경
                        for (index, keyring) in keyrings.enumerated() {
                            if keyring == documentId {
                                keyrings[index] = "none"
                                needsUpdate = true
                            }
                        }
                        
                        if needsUpdate {
                            let bundleRef = db.collection("KeyringBundle").document(document.documentID)
                            batch.updateData(["keyrings": keyrings], forDocument: bundleRef)
                        }
                    }
                }
                
                // 3. Batch 커밋 - 모든 작업이 성공하거나 모두 실패
                batch.commit { [weak self] error in
                    guard let self = self else {
                        completion(false)
                        return
                    }
                    
                    if let error = error {
                        completion(false)
                        return
                    }
                    
                    // 4. 로컬 데이터 정리
                    if let index = self.keyring.firstIndex(where: { $0.id == keyring.id }) {
                        self.keyring.remove(at: index)
                    }

                    // 5. 매핑 Dictionary에서도 제거
                    self.keyringDocumentIdByLocalId.removeValue(forKey: keyring.id)

                    // 6. App Group 위젯용 캐시에서도 제거
                    KeyringImageCache.shared.removeKeyring(id: documentId)

                    completion(true)
                }
            }
    }
    
    // MARK: - 키링 복사
    func copyKeyring(
        uid: String,
        keyring: Keyring,
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("키링 복사 시작 - 원본 이름: \(keyring.name)")
        
        // 복사할 키링의 Firestore documentId 가져오기
        guard let originalDocumentId = keyringDocumentIdByLocalId[keyring.id] else {
            completion(false, nil)
            return
        }
        
        let db = Firestore.firestore()
        
        // originalId 이미 존재하면 그걸로, 비어있으면 선택된 키링 Id
        let baseOriginalId = keyring.originalId ?? originalDocumentId
        
        // 새 키링 생성 (원본 키링의 데이터 복사, originalId에 원본 ID 저장)
        let copiedKeyring = Keyring(
            name: keyring.name,
            bodyImage: keyring.bodyImage,
            soundId: keyring.soundId,
            particleId: keyring.particleId,
            memo: keyring.memo,
            tags: [],
            createdAt: Date(),  // 복사 시점
            authorId: uid,      // 어차피 본인
            selectedTemplate: keyring.selectedTemplate,
            selectedRing: keyring.selectedRing,
            selectedChain: keyring.selectedChain,
            originalId: baseOriginalId,
            chainLength: keyring.chainLength
        )
        
        let keyringData = copiedKeyring.toDictionary()
        
        // Firestore에 새 키링 문서 생성
        let docRef = db.collection("Keyring").document()
        
        docRef.setData(keyringData) { [weak self] error in
            guard error == nil else { completion(false, nil); return }
            
            let newKeyringId = docRef.documentID
            
            // User 문서의 keyrings 배열에 새 키링 ID 추가 및 복사권 차감
            db.collection("User")
                .document(uid)
                .updateData([
                    "copyVoucher": FieldValue.increment(Int64(-1)),
                    "keyrings": FieldValue.arrayUnion([newKeyringId])
                ]) { error in
                    if let error = error {
                        completion(false, nil)
                        return
                    }
                    
                    // 로컬 배열에도 추가
                    self?.keyring.append(copiedKeyring)
                    
                    // 매핑 Dictionary에 추가
                    self?.keyringDocumentIdByLocalId[copiedKeyring.id] = newKeyringId
                    
                    // 복사권 차감
                    if let currentVoucher = self?.copyVoucher {
                        self?.copyVoucher = max(0, currentVoucher - 1)
                    }
                    
                    completion(true, newKeyringId)
                }
        }
    }
}
