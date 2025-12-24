//
//  CollectionViewModel+Tags.swift
//  Keychy
//
//  Created by Jini on 11/3/25.
//

import SwiftUI
import FirebaseFirestore

extension CollectionViewModel {
    
    // 태그 이름 변경
    func renameTag(uid: String, oldName: String, newName: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // User 문서 가져오기
        db.collection("User")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                guard error == nil else { completion(false); return }
                
                guard let data = snapshot?.data() else {
                    // 유저 데이터 없음
                    completion(false)
                    return
                }
                
                // User의 태그 목록
                guard var tags = data["tags"] as? [String] else {
                    // 태그 목록 찾을 수 없음
                    completion(false)
                    return
                }
                
                // User의 보유 키링 ID 목록
                guard let keyringIds = data["keyrings"] as? [String] else {
                    // 보유 키링 목록 찾을 수 없음
                    completion(false)
                    return
                }
                
                // 태그 이름 변경
                guard let index = tags.firstIndex(of: oldName) else {
                    // 변경할 태그 찾을 수 없음
                    completion(false)
                    return
                }
                
                tags[index] = newName
                
                // User 문서의 tags 배열 업데이트
                db.collection("User")
                    .document(uid)
                    .updateData(["tags": tags]) { error in
                        guard error == nil else { completion(false); return }
                        
                        // 보유한 키링들의 태그 업데이트
                        self.updateKeyringTags(
                            keyringIds: keyringIds,
                            oldTagName: oldName,
                            newTagName: newName,
                            completion: completion
                        )
                    }
            }
    }
    
    // 태그 삭제
    func deleteTag(uid: String, tagName: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // User 문서 가져오기
        db.collection("User")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                guard error == nil else { completion(false); return }
                
                guard let data = snapshot?.data() else {
                    // 유저 데이터 없음
                    completion(false)
                    return
                }
                
                // User의 보유 키링 ID 목록
                guard let keyringIds = data["keyrings"] as? [String] else {
                    // 보유한 키링 목록 찾기 못함
                    completion(false)
                    return
                }
                
                // User 문서에서 태그 삭제
                db.collection("User")
                    .document(uid)
                    .updateData([
                        "tags": FieldValue.arrayRemove([tagName])
                    ]) { error in
                        guard error == nil else { completion(false); return }
                        
                        // 보유한 키링들에서 태그 제거
                        self.removeTagFromKeyrings(
                            keyringIds: keyringIds,
                            tagName: tagName,
                            completion: completion
                        )
                    }
            }
    }
    
    // 특정 키링들의 태그 이름 변경
    private func updateKeyringTags(
        keyringIds: [String],
        oldTagName: String,
        newTagName: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard !keyringIds.isEmpty else {
            // 보유한 키링 없음
            completion(true)
            return
        }
        
        let db = Firestore.firestore()
        
        let batchSize = 10
        let batches = stride(from: 0, to: keyringIds.count, by: batchSize).map {
            Array(keyringIds[$0..<min($0 + batchSize, keyringIds.count)])
        }
        
        let dispatchGroup = DispatchGroup()
        var updateCount = 0
        var hasError = false
        
        for (batchIndex, batch) in batches.enumerated() {
            dispatchGroup.enter()
            
            // 해당 배치의 키링들 중 oldTagName을 포함하는 것만 찾기
            db.collection("Keyring")
                .whereField(FieldPath.documentID(), in: batch)
                .whereField("tags", arrayContains: oldTagName)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    guard error == nil else { completion(false); return }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        return
                    }
                    
                    // 배치 작업으로 업데이트
                    let writeBatch = db.batch()
                    
                    for document in documents {
                        var tags = document.data()["tags"] as? [String] ?? []
                        
                        // 기존 태그를 새 태그로 변경
                        if let index = tags.firstIndex(of: oldTagName) {
                            tags[index] = newTagName
                            
                            let docRef = db.collection("Keyring").document(document.documentID)
                            writeBatch.updateData(["tags": tags], forDocument: docRef)
                            
                            updateCount += 1
                        }
                    }
                    
                    // 배치 커밋
                    writeBatch.commit { error in
                        guard error == nil else { completion(false); return }
                    }
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError {
                // 업데이트 오류 발생
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // 특정 키링들에서 태그 제거
    private func removeTagFromKeyrings(
        keyringIds: [String],
        tagName: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard !keyringIds.isEmpty else {
            // 보유한 키링 없음
            completion(true)
            return
        }
        
        let db = Firestore.firestore()
        
        let batchSize = 10
        let batches = stride(from: 0, to: keyringIds.count, by: batchSize).map {
            Array(keyringIds[$0..<min($0 + batchSize, keyringIds.count)])
        }
        
        let dispatchGroup = DispatchGroup()
        var removeCount = 0
        var hasError = false
        
        for (batchIndex, batch) in batches.enumerated() {
            dispatchGroup.enter()
            
            // 해당 배치의 키링들 중 tagName을 포함하는 것만 찾기
            db.collection("Keyring")
                .whereField(FieldPath.documentID(), in: batch)
                .whereField("tags", arrayContains: tagName)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        hasError = true
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        return
                    }
                    
                    // 배치 작업으로 삭제
                    let writeBatch = db.batch()
                    
                    for document in documents {
                        let docRef = db.collection("Keyring").document(document.documentID)
                        writeBatch.updateData([
                            "tags": FieldValue.arrayRemove([tagName])
                        ], forDocument: docRef)
                        
                        removeCount += 1
                    }
                    
                    // 배치 커밋
                    writeBatch.commit { error in
                        if let error = error {
                            // 삭제 실패
                            hasError = true
                        }
                    }
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError {
                // 삭제 중 오류 발생
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // 태그 추가
    func addNewTag(uid: String, newTagName: String) {

        let db = Firestore.firestore()
        
        db.collection("User")
            .document(uid)
            .updateData([
                "tags": FieldValue.arrayUnion([newTagName])
            ]) { error in
                if let error = error {
                    print("태그 추가 실패: \(error.localizedDescription)")
                    return
                }
                
                print("Firestore에 태그 추가 완료: \(newTagName)")
                
            }
    }
}
