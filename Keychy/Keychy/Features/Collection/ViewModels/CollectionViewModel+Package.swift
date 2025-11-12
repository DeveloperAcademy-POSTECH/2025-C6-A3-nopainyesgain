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
            "isPackaged": true
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
                guard let shareLink = DeepLinkManager.createShareLink(postOfficeId: postOfficeId) else {
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
                    
                    // 5. Bundle에서 키링 제거
                    self.removeKeyringFromBundles(
                        uid: uid,
                        keyringId: documentId
                    ) { bundleSuccess in
                        if bundleSuccess {
                            print("Bundle에서 키링 제거 완료")
                        } else {
                            print("Bundle에서 키링 제거 실패 (Bundle 없음)")
                        }
                        
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
    
    // MARK: - Bundle에서 키링 제거
    private func removeKeyringFromBundles(
        uid: String,
        keyringId: String,
        completion: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        
        // 해당 사용자의 모든 Bundle 조회
        db.collection("KeyringBundle")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { snapshot, error in
                if error != nil {
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("Bundle 없음")
                    completion(true)
                    return
                }
                
                let batch = db.batch()
                var updatedCount = 0
                
                // 각 Bundle에서 해당 키링 ID 제거
                for document in documents {
                    guard var keyrings = document.data()["keyrings"] as? [String] else {
                        continue
                    }
                    
                    var needsUpdate = false
                    
                    // 배열을 순회하면서 keyringId를 "none"으로 변경
                    for (index, keyring) in keyrings.enumerated() {
                        if keyring == keyringId {
                            keyrings[index] = "none"
                            needsUpdate = true
                            print("Bundle '\(document.documentID)'의 인덱스 \(index)를 'none'으로 변경 예정")
                        }
                    }
                    
                    if needsUpdate {
                        let bundleRef = db.collection("KeyringBundle").document(document.documentID)
                        batch.updateData(["keyrings": keyrings], forDocument: bundleRef)
                        updatedCount += 1
                    }
                }
                
                if updatedCount == 0 {
                    print("키링이 포함된 Bundle 없음")
                    completion(true)
                    return
                }
                
                // Batch 커밋
                batch.commit { error in
                    if let error = error {
                        print("Bundle 업데이트 실패: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    print("\(updatedCount)개 Bundle에서 키링 제거 완료")
                    completion(true)
                }
            }
    }
    
    // MARK: - PostOffice에서 키링 정보 가져오기
    func fetchKeyringFromPostOffice(postOfficeId: String, completion: @escaping (Keyring?, String?) -> Void) {
        print("PostOffice 정보 로드 시작 - ID: \(postOfficeId)")
        
        let db = Firestore.firestore()
        
        db.collection("PostOffice")
            .document(postOfficeId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("PostOffice 로드 에러: \(error.localizedDescription)")
                    completion(nil, nil)
                    return
                }
                
                guard let document = snapshot,
                      document.exists,
                      let data = document.data(),
                      let keyringId = data["keyringId"] as? String else {
                    print("PostOffice 문서가 존재하지 않거나 keyringId 없음")
                    completion(nil, nil)
                    return
                }
                
                print("PostOffice에서 keyringId 추출: \(keyringId)")
                
                // keyringId로 실제 키링 데이터 가져오기
                self.fetchKeyringById(keyringId: keyringId) { keyring in
                    completion(keyring, keyringId)
                }
            }
    }
    
    // MARK: - PostOffice 데이터 가져오기
    func fetchPostOfficeData(postOfficeId: String, completion: @escaping ([String: Any]?) -> Void) {
        print("PostOffice 데이터 로드 - ID: \(postOfficeId)")
        
        let db = Firestore.firestore()
        
        db.collection("PostOffice")
            .document(postOfficeId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("PostOffice 로드 에러: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot,
                      document.exists,
                      let data = document.data(),
                      let senderId = data["senderId"] as? String,
                      let keyringId = data["keyringId"] as? String else {
                    print("PostOffice 문서 데이터 없음")
                    completion(nil)
                    return
                }
                
                print("PostOffice 데이터 조회 성공")
                
                let postOfficeData: [String: Any] = [
                    "senderId": senderId,
                    "keyringId": keyringId
                ]
                
                completion(postOfficeData)
            }
    }

    // MARK: - 키링 수락 (발신자 → 수신자)
    func acceptKeyring(
        postOfficeId: String,
        keyringId: String,
        senderId: String,
        receiverId: String,
        completion: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()

        // 1. Keyring 문서 조회 (bodyImage, soundId 가져오기)
        db.collection("Keyring").document(keyringId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let bodyImage = data["bodyImage"] as? String,
                  let soundId = data["soundId"] as? String else {
                print("키링 수락 실패: Keyring 문서 조회 실패")
                completion(false)
                return
            }

            // 2. Storage 리소스 재업로드
            Task {
                do {
                    let (newBodyImageURL, newSoundId) = try await self.reuploadKeyringResources(
                        bodyImage: bodyImage,
                        soundId: soundId,
                        toUserId: receiverId
                    )

                    // 3. Batch 작업 (새 URL 포함)
                    let batch = db.batch()

                    // 3-1. Sender의 keyrings 배열에서 제거
                    let senderRef = db.collection("User").document(senderId)
                    batch.updateData([
                        "keyrings": FieldValue.arrayRemove([keyringId])
                    ], forDocument: senderRef)

                    // 3-2. Receiver의 keyrings 배열에 추가
                    let receiverRef = db.collection("User").document(receiverId)
                    batch.updateData([
                        "keyrings": FieldValue.arrayUnion([keyringId])
                    ], forDocument: receiverRef)

                    // 3-3. PostOffice 문서 업데이트
                    let postOfficeRef = db.collection("PostOffice").document(postOfficeId)
                    batch.updateData([
                        "receiverId": receiverId,
                        "endedAt": Timestamp(date: Date())
                    ], forDocument: postOfficeRef)

                    // 3-4. Keyring 문서 업데이트 (새 URL 포함!)
                    let keyringRef = db.collection("Keyring").document(keyringId)
                    batch.updateData([
                        "isPackaged": false,
                        "tags": [],
                        "bodyImage": newBodyImageURL,
                        "soundId": newSoundId,
                        "isNew": true,
                        "senderId": senderId,
                        "receivedAt": Timestamp(date: Date())
                    ], forDocument: keyringRef)

                    // 4. Batch 실행
                    batch.commit { [weak self] error in
                        if let error = error {
                            print("키링 수락 실패: \(error.localizedDescription)")
                            completion(false)
                            return
                        }

                        // 로컬 데이터 업데이트
                        if let index = self?.keyring.firstIndex(where: { $0.id.uuidString == keyringId }) {
                            self?.keyring[index].isPackaged = false
                            self?.keyring[index].bodyImage = newBodyImageURL
                            self?.keyring[index].soundId = newSoundId
                            self?.keyring[index].isNew = true
                            self?.keyring[index].senderId = senderId
                            self?.keyring[index].receivedAt = Date()
                        }

                        // 위젯 캐시 제거 (새 이미지로 갱신 필요)
                        KeyringImageCache.shared.removeKeyring(id: keyringId)

                        print("키링 수락 완료")
                        completion(true)
                    }

                } catch {
                    print("키링 수락 실패: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - 포장 풀기
    func unpackKeyring(
        uid: String,
        keyring: Keyring,
        postOfficeId: String,
        completion: @escaping (Bool) -> Void
    ) {
        
        guard let documentId = keyringDocumentIdByLocalId[keyring.id] else {
            print("키링 문서 ID 없음")
            completion(false)
            return
        }

        let db = Firestore.firestore()
        let batch = db.batch()

        // isPackaged 상태 해제
        let keyringRef = db.collection("Keyring").document(documentId)
        batch.updateData(["isPackaged": false], forDocument: keyringRef)

        // PostOffice 문서 삭제
        let postOfficeRef = db.collection("PostOffice").document(postOfficeId)
        batch.deleteDocument(postOfficeRef)
        
        batch.commit { [weak self] error in
            if let error = error {
                print("포장 풀기 실패: \(error.localizedDescription)")
                completion(false)
                return
            }

            print("포장 풀기 완료: \(keyring.name)")

            // 로컬 상태 갱신
            if let index = self?.keyring.firstIndex(where: { $0.id == keyring.id }) {
                self?.keyring[index].isPackaged = false
                self?.keyring[index].isEditable = true
            }

            completion(true)
        }


    }
}
