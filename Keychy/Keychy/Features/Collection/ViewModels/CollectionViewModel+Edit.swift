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
                
                if let error = error {
                    print("❌ 키링 업데이트 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }

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
                
                if let error = error {
                    // Keyring 문서 삭제 실패
                    completion(false)
                    return
                }
                
                // User 컬렉션에서 keyrings 배열에서 해당 키링 ID 제거
                db.collection("User")
                    .document(uid)
                    .updateData([
                        "keyrings": FieldValue.arrayRemove([documentId])
                    ]) { error in
                        if let error = error {
                            // User의 keyrings 배열 업데이트 실패
                            completion(false)
                            return
                        }
                        
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
}
