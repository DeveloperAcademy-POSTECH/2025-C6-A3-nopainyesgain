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
        print("키링 삭제 시작 - ID: \(keyring.id)")
        
        guard let documentId = keyringDocumentIdByLocalId[keyring.id] else {
            print("⚠️ 키링 업데이트 실패: Firestore documentId를 찾을 수 없습니다")
            print("현재 keyring.id: \(keyring.id)")
            print("매핑 Dictionary 키들: \(keyringDocumentIdByLocalId.keys)")
            completion(false)
            return
        }
        
        let db = Firestore.firestore()

    }
}
