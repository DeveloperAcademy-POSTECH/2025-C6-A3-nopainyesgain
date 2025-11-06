//
//  CollectionViewModel+Edit.swift
//  Keychy
//
//  Created by Jini on 11/6/25.
//

import SwiftUI
import FirebaseFirestore

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

        // Keyring 컬렉션에서 해당 키링 문서 삭제
        db.collection("Keyring")
            .document(documentId)
            .delete { [weak self] error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                guard error == nil else { completion(false); return }
                
                // User 컬렉션에서 keyrings 배열에서 해당 키링 ID 제거
                db.collection("User")
                    .document(uid)
                    .updateData([
                        "keyrings": FieldValue.arrayRemove([documentId])
                    ]) { error in
                        guard error == nil else { completion(false); return }
                        
                        // 로컬 데이터에서도 제거
                        if let index = self.keyring.firstIndex(where: { $0.id == keyring.id }) {
                            self.keyring.remove(at: index)
                        }
                        
                        // 매핑 Dictionary에서도 제거
                        self.keyringDocumentIdByLocalId.removeValue(forKey: keyring.id)

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
            originalId: originalDocumentId,
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
