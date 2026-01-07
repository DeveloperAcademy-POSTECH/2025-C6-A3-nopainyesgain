//
//  CollectionViewModel+Distribution.swift
//  Keychy
//
//  Created by Jini on 11/19/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - 배포 로직
extension CollectionViewModel {
    // MARK: - 키링 수령 (배포용)
    func collectKeyring(
        keyringId: String,
        senderId: String,
        receiverId: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        // 1. 기존 fetchKeyringById로 키링 데이터 가져오기
        fetchKeyringById(keyringId: keyringId) { [weak self] fetchedKeyring in
            guard let self = self,
                  let originalKeyring = fetchedKeyring else {
                completion(false, "키링 로드 실패")
                return
            }

            // 2. Storage 리소스 재업로드 및 복사
            Task {
                do {
                    let (newBodyImageURL, newSoundId) = try await self.reuploadKeyringResources(
                        bodyImage: originalKeyring.bodyImage,
                        soundId: originalKeyring.soundId,
                        toUserId: receiverId
                    )
                    
                    // 3. 새 키링 생성 (복사본)
                    let copiedKeyring = Keyring(
                        name: originalKeyring.name,
                        bodyImage: newBodyImageURL,
                        soundId: newSoundId,
                        particleId: originalKeyring.particleId,
                        memo: originalKeyring.memo,
                        tags: [],
                        createdAt: originalKeyring.createdAt,
                        authorId: originalKeyring.authorId,
                        selectedTemplate: originalKeyring.selectedTemplate,
                        selectedRing: originalKeyring.selectedRing,
                        selectedChain: originalKeyring.selectedChain,
                        originalId: keyringId,
                        chainLength: originalKeyring.chainLength,
                        isEditable: false,
                        isNew: true,
                        senderId: senderId,
                        receivedAt: Date(),
                        hookOffsetY: originalKeyring.hookOffsetY
                    )
                    
                    // 4. Firestore에 새 키링 문서 생성
                    let db = Firestore.firestore()
                    let newKeyringRef = db.collection("Keyring").document()
                    try await newKeyringRef.setData(copiedKeyring.toDictionary())
                    
                    let newKeyringId = newKeyringRef.documentID
                    
                    // 5. User의 keyrings 배열에 추가
                    try await db.collection("User")
                        .document(receiverId)
                        .updateData([
                            "keyrings": FieldValue.arrayUnion([newKeyringId])
                        ])
                    
                    // 6. 로컬 상태 업데이트
                    await MainActor.run {
                        self.keyring.append(copiedKeyring)
                        self.keyringDocumentIdByLocalId[copiedKeyring.id] = newKeyringId
                    }

                    // 7. 키링 이펙트 동기화 (백그라운드)
                    Task.detached(priority: .background) {
                        await EffectSyncManager.shared.syncKeyringEffects(
                            soundId: originalKeyring.soundId,
                            particleId: originalKeyring.particleId
                        )
                    }

                    print("키링 수령 완료 (배포): \(originalKeyring.name)")
                    completion(true, newKeyringId)
                    
                } catch {
                    print("키링 수령 실패: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
}
