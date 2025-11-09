//
//  CollectionViewModel+Package.swift
//  Keychy
//
//  Created by Jini on 11/9/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - 포장 처리
extension CollectionViewModel {
    
    // MARK: - 포장 상태 업데이트
    func packageKeyring(
        uid: String,
        keyring: Keyring,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard let documentId = keyringDocumentIdByLocalId[keyring.id] else {
            print("키링 문서 ID 없음")
            completion(false, nil)
            return
        }
        
        let db = Firestore.firestore()
        
        // 1. Keyring 상태 업데이트
        let keyringUpdateData: [String: Any] = [
            "isPackaged": true,
            "isEditable": false
        ]
        
        db.collection("Keyring")
            .document(documentId)
            .updateData(keyringUpdateData) { [weak self] error in
                guard let self = self else {
                    completion(false, nil)
                    return
                }
                
                if let error = error {
                    print("Keyring 상태 업데이트 실패: \(error.localizedDescription)")
                    completion(false, nil)
                    return
                }
                
                print("Keyring 상태 업데이트 완료")
                
                // 2. PostOffice 문서 먼저 생성 (shareLink 없이)
                let postOfficeRef = db.collection("PostOffice").document()
                let postOfficeId = postOfficeRef.documentID
                
                print("PostOffice 문서 ID 생성: \(postOfficeId)")
                
                // 3. PostOffice ID로 공유 링크 생성
                guard let shareLink = DeepLinkManager.createShareLink(keyringId: postOfficeId) else {
                    print("공유 링크 생성 실패")
                    completion(false, nil)
                    return
                }
                
                print("공유 링크 생성: \(shareLink.absoluteString)")
                
                // 4. PostOffice 문서 생성
                let postOfficeData: [String: Any] = [
                    "senderId": uid,
                    "keyringId": documentId,
                    "shareLink": shareLink.absoluteString,
                    "createdAt": Timestamp(date: Date())
                ]
                
                postOfficeRef.setData(postOfficeData) { error in
                    if let error = error {
                        print("PostOffice 문서 생성 실패: \(error.localizedDescription)")
                        completion(false, nil)
                        return
                    }
                    
                    print("PostOffice 문서 생성 완료: \(postOfficeId)")
                    
                    // 로컬 상태 업데이트
                    if let index = self.keyring.firstIndex(where: { $0.id == keyring.id }) {
                        self.keyring[index].isPackaged = true
                        self.keyring[index].isEditable = false
                    }
                    
                    completion(true, postOfficeId)
                }
            }
    }
    
}
