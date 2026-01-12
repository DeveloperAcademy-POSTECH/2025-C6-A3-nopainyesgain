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
                
                postOfficeRef.getDocument { [weak self] checkSnapshot, checkError in
                    guard let self = self else {
                        completion(false, nil)
                        return
                    }
                    
                    if checkSnapshot?.exists == true {
                        print("[희귀 케이스] PostOffice ID 중복 발견 - 재시도")
                        
                        // 재귀 호출로 다시 시도 (최대 3회 정도)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.packageKeyring(uid: uid, keyring: keyring, completion: completion)
                        }
                        return
                    }
                    
                    // 3. PostOffice ID로 공유 링크 생성
                    guard let shareLink = DeepLinkManager.createShareLink(postOfficeId: postOfficeId) else {
                        print("공유 링크 생성 실패")
                        completion(false, nil)
                        return
                    }
                    
                    print("공유 링크 생성: \(shareLink.absoluteString)")
                    
                    // 4. PostOffice 문서 생성
                    let postOfficeData: [String: Any] = [
                        "type": "receive",
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
                var affectedBundleIds: [String] = []
                
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
                        affectedBundleIds.append(document.documentID)
                    }
                }
                
                if affectedBundleIds.isEmpty {
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
                    
                    print("\(affectedBundleIds.count)개 Bundle에서 키링 제거 완료")
                    
                    // 변경된 Bundle들의 캡처 캐시 삭제
                    for bundleId in affectedBundleIds {
                        BundleImageCache.shared.delete(for: bundleId)
                        print("Bundle 캡처 캐시 삭제: \(bundleId)")
                    }
                    
                    completion(true)
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
                
                var postOfficeData: [String: Any] = [
                    "senderId": senderId,
                    "keyringId": keyringId
                ]
                
                // receiverId 필드가 있으면 포함
                if let receiverId = data["receiverId"] as? String {
                    postOfficeData["receiverId"] = receiverId
                }
                
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
        
        Task {
            do {
                // 1차 검증 - 리소스 복사 전 사전 체크
                let preCheckDoc = try await db.collection("PostOffice").document(postOfficeId).getDocument()
                
                guard preCheckDoc.exists else {
                    await MainActor.run { completion(false) }
                    return
                }
                
                // 1차 중복 수락 체크
                if let existingReceiverId = preCheckDoc.data()?["receiverId"] as? String,
                   !existingReceiverId.isEmpty {
                    await MainActor.run { completion(false) }
                    return
                }
                
                // 키링 데이터 조회 및 리소스 처리
                let keyringDoc = try await db.collection("Keyring").document(keyringId).getDocument()
                
                guard let keyringData = keyringDoc.data(),
                      let bodyImage = keyringData["bodyImage"] as? String,
                      let soundId = keyringData["soundId"] as? String,
                      let keyringName = keyringData["name"] as? String else {
                    await MainActor.run { completion(false) }
                    return
                }
        
                let (newBodyImageURL, newSoundId) = try await self.reuploadKeyringResources(
                    bodyImage: bodyImage,
                    soundId: soundId,
                    toUserId: receiverId
                )
                
                // Transaction으로 중복 수락 방지
                db.runTransaction({ (transaction, errorPointer) -> [String: Any]? in
                    // PostOffice 재검증
                    let postOfficeRef = db.collection("PostOffice").document(postOfficeId)
                    let postOfficeDocument: DocumentSnapshot
                    do {
                        postOfficeDocument = try transaction.getDocument(postOfficeRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }

                    guard postOfficeDocument.exists else {
                        let error = NSError(domain: "AppErrorDomain", code: -1,
                                          userInfo: [NSLocalizedDescriptionKey: "PostOffice 문서가 존재하지 않습니다"])
                        errorPointer?.pointee = error
                        return nil
                    }
                    
                    // 2차 중복 수락 체크
                    if let existingReceiverId = postOfficeDocument.data()?["receiverId"] as? String,
                       !existingReceiverId.isEmpty {
                        let error = NSError(domain: "AppErrorDomain", code: -2,
                                          userInfo: [NSLocalizedDescriptionKey: "이미 수락된 선물입니다"])
                        errorPointer?.pointee = error
                        return nil
                    }
                    
                    // Receiver 보관함 용량 체크
                    let receiverRef = db.collection("User").document(receiverId)
                    let receiverDoc: DocumentSnapshot
                    do {
                        receiverDoc = try transaction.getDocument(receiverRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                    
                    guard let receiverData = receiverDoc.data(),
                          let receiverKeyrings = receiverData["keyrings"] as? [String],
                          let maxKeyringCount = receiverData["maxKeyringCount"] as? Int else {
                        let error = NSError(domain: "AppErrorDomain", code: -5,
                                          userInfo: [NSLocalizedDescriptionKey: "받는 사람의 데이터를 조회할 수 없습니다"])
                        errorPointer?.pointee = error
                        return nil
                    }

                    if receiverKeyrings.count >= maxKeyringCount {
                        let error = NSError(domain: "AppErrorDomain", code: -4,
                                          userInfo: [NSLocalizedDescriptionKey: "받는 사람의 보관함이 가득 찼습니다"])
                        errorPointer?.pointee = error
                        return nil
                    }
                    
                    // 모든 문서 업데이트
                    let senderRef = db.collection("User").document(senderId)
                    let keyringRef = db.collection("Keyring").document(keyringId)
                    
                    // PostOffice 업데이트
                    transaction.updateData([
                        "receiverId": receiverId,
                        "endedAt": Timestamp(date: Date())
                    ], forDocument: postOfficeRef)
                    
                    // Sender에서 키링 제거
                    transaction.updateData([
                        "keyrings": FieldValue.arrayRemove([keyringId])
                    ], forDocument: senderRef)
                    
                    // Receiver에게 키링 추가
                    transaction.updateData([
                        "keyrings": FieldValue.arrayUnion([keyringId])
                    ], forDocument: receiverRef)
                    
                    // Keyring 문서 업데이트
                    transaction.updateData([
                        "isPackaged": false,
                        "tags": [],
                        "bodyImage": newBodyImageURL,
                        "soundId": newSoundId,
                        "isNew": true,
                        "senderId": senderId,
                        "receivedAt": Timestamp(date: Date())
                    ], forDocument: keyringRef)
                    
                    // Transaction 완료 후 처리할 데이터 반환
                    return [
                        "keyringName": keyringName,
                        "newBodyImageURL": newBodyImageURL,
                        "newSoundId": newSoundId,
                        "particleId": keyringData["particleId"] as? String ?? ""
                    ]
                }) { [weak self] (result, error) in
                    guard let self = self else {
                        completion(false)
                        return
                    }
                    
                    if let error = error {
                        print("[Transaction 실패] \(error.localizedDescription)")
                        
                        // TODO: 복사된 리소스 삭제
                        if (error as NSError).code == -2 {
                            print("중복 수락 감지")
                        }
                        completion(false)
                        return
                    }
                    
                    guard let transactionData = result as? [String: Any],
                          let keyringName = transactionData["keyringName"] as? String,
                          let newBodyImageURL = transactionData["newBodyImageURL"] as? String,
                          let newSoundId = transactionData["newSoundId"] as? String else {
                        completion(false)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        // UI 즉시 업데이트
                        if let index = self.keyring.firstIndex(where: { $0.id.uuidString == keyringId }) {
                            self.keyring[index].isPackaged = false
                            self.keyring[index].bodyImage = newBodyImageURL
                            self.keyring[index].soundId = newSoundId
                            self.keyring[index].isNew = true
                            self.keyring[index].senderId = senderId
                            self.keyring[index].receivedAt = Date()
                        }
                        
                        // 위젯 캐시 정리
                        KeyringImageCache.shared.removeKeyring(id: keyringId)
                        
                        // 사용자에게 즉시 성공 알림
                        completion(true)
                    }
                    
                    // 네트워크/백그라운드 작업 (사용자가 기다릴 필요 없는 것들)
                    Task.detached(priority: .background) {
                        // 알림 전송 로직 - 원래 키링 소유자에게 "XX님이 선물을 수락했어요!"
                        await self.createGiftAcceptedNotification(
                            keyringOriginalOwnerId: senderId,
                            giftRecipientId: receiverId,
                            keyringName: keyringName,
                            postOfficeId: postOfficeId
                        )

                        // 키링 이펙트 동기화 (백그라운드)
                        if let particleId = transactionData["particleId"] as? String, !particleId.isEmpty {
                            await EffectSyncManager.shared.syncKeyringEffects(
                                soundId: newSoundId,
                                particleId: particleId
                            )
                        }
                    }
                } 
            } catch {
                print("[전체 실패] \(error.localizedDescription)")
                await MainActor.run { completion(false) }
            }
        }
    }
    
    // MARK: - 포장 풀기
    func unpackKeyring(
        uid: String,
        keyring: Keyring,
        postOfficeId: String,
        completion: @escaping (Bool, Bool) -> Void // (성공여부, 이미수락여부)
    ) {
        
        guard let documentId = keyringDocumentIdByLocalId[keyring.id] else {
            print("키링 문서 ID 없음")
            completion(false, false)
            return
        }

        let db = Firestore.firestore()
        let postOfficeRef = db.collection("PostOffice").document(postOfficeId)
        
        // Transaction으로 동시 접근 방지
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let postOfficeDocument: DocumentSnapshot
            do {
                try postOfficeDocument = transaction.getDocument(postOfficeRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            // PostOffice 문서가 존재하는지 확인
            guard postOfficeDocument.exists else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "PostOffice 문서가 존재하지 않습니다"]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            // 이미 receiverId가 설정되어 있는지 확인 (acceptKeyring과 동일한 로직)
            if let existingReceiverId = postOfficeDocument.data()?["receiverId"] as? String,
               !existingReceiverId.isEmpty {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "이미 수락된 선물입니다"]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            // Transaction 내에서 PostOffice 문서 삭제
            transaction.deleteDocument(postOfficeRef)
            
            // Transaction 내에서 Keyring 상태 업데이트
            let keyringRef = db.collection("Keyring").document(documentId)
            transaction.updateData(["isPackaged": false], forDocument: keyringRef)

            return nil
        }) { [weak self] (object, error) in
            guard let self = self else {
                completion(false, false)
                return
            }
            
            if let error = error {
                print("포장 풀기 실패 (Transaction): \(error.localizedDescription)")
                
                // 에러 코드 -2는 이미 수락됨
                if (error as NSError).code == -2 {
                    print("이미 수락된 선물 - 언팩 불가")
                    completion(false, true) // 실패, 이미수락됨
                    return
                }
                
                completion(false, false)
                return
            }
            
            // Transaction 성공
            print("포장 풀기 완료 (Transaction): \(keyring.name)")
            
            // 로컬 상태 갱신
            if let index = self.keyring.firstIndex(where: { $0.id == keyring.id }) {
                self.keyring[index].isPackaged = false
                self.keyring[index].isEditable = true
            }
            
            completion(true, false) // 성공, 이미수락안됨
        }

    }

    // MARK: - 선물 수락 알림 생성
    /// 키링 원래 소유자에게 "XX님이 선물을 수락했어요!" 알림 전송
    private func createGiftAcceptedNotification(
        keyringOriginalOwnerId: String,  // 키링 원래 소유자 (알림 받을 사람)
        giftRecipientId: String,         // 선물 받은 사람 (알림에 표시될 이름)
        keyringName: String,
        postOfficeId: String
    ) {
        let db = Firestore.firestore()

        // 1. 선물 받은 사람의 닉네임 조회
        db.collection("User").document(giftRecipientId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let giftRecipientNickname = data["nickname"] as? String else {
                print("알림 생성 실패: 선물 받은 사람 닉네임 조회 실패")
                return
            }

            // 2. KeychyNotification 생성
            let notification = KeychyNotification(
                type: .giftAccepted,
                receiverId: keyringOriginalOwnerId,  // 알림 받을 사람 = 키링 원래 소유자
                senderId: giftRecipientId,           // 알림 발신자 = 선물 받은 사람
                senderNickname: giftRecipientNickname,  // "영희님이 선물을 수락했어요!"
                keyringName: keyringName,
                postOfficeId: postOfficeId,
                isRead: false,
                createdAt: Date()
            )

            // 3. Firestore에 알림 문서 추가
            db.collection("Notifications").addDocument(data: notification.toDictionary()) { error in
                if let error = error {
                    print("알림 생성 실패: \(error.localizedDescription)")
                } else {
                    print("알림 생성 완료: \(giftRecipientNickname)님이 '\(keyringName)' 선물을 수락했습니다")
                }
            }
        }
    }
}
