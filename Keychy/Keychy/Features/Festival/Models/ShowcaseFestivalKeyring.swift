//
//  ShowcaseFestivalKeyring.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import Foundation
import FirebaseFirestore

/// 쇼케이스 페스티벌 키링 모델
struct ShowcaseFestivalKeyring: Identifiable, Hashable {
    var id: String  // Firestore document ID
    var name: String
    var authorId: String
    var bodyImageURL: String
    var gridIndex: Int
    var isEditing: Bool
    var editingUserNickname: String  // 수정 중인 사용자 닉네임
    var editingStartedAt: Date?  // 수정 시작 시간 (자동 만료용)
    var keyringId: String
    var memo: String
    var particleId: String
    var soundId: String
    var createdAt: Date
    var votes: Int

    init(id: String = UUID().uuidString,
         name: String = "",
         authorId: String = "",
         bodyImageURL: String = "",
         gridIndex: Int = 0,
         isEditing: Bool = false,
         editingUserNickname: String = "",
         editingStartedAt: Date? = nil,
         keyringId: String = "none",
         memo: String = "none",
         particleId: String = "none",
         soundId: String = "none",
         createdAt: Date = Date(),
         votes: Int = 0) {
        self.id = id
        self.name = name
        self.authorId = authorId
        self.bodyImageURL = bodyImageURL
        self.gridIndex = gridIndex
        self.isEditing = isEditing
        self.editingUserNickname = editingUserNickname
        self.editingStartedAt = editingStartedAt
        self.keyringId = keyringId
        self.memo = memo
        self.particleId = particleId
        self.soundId = soundId
        self.createdAt = createdAt
        self.votes = votes
    }

    /// Firestore 문서에서 초기화
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        self.id = document.documentID
        self.name = data["name"] as? String ?? ""
        self.authorId = data["authorId"] as? String ?? ""
        self.bodyImageURL = data["bodyImageURL"] as? String ?? ""
        self.gridIndex = data["gridIndex"] as? Int ?? 0
        self.isEditing = data["isEditing"] as? Bool ?? false
        self.editingUserNickname = data["editingUserNickname"] as? String ?? ""
        if let editingTimestamp = data["editingStartedAt"] as? Timestamp {
            self.editingStartedAt = editingTimestamp.dateValue()
        } else {
            self.editingStartedAt = nil
        }
        self.keyringId = data["keyringId"] as? String ?? "none"
        self.memo = data["memo"] as? String ?? "none"
        self.particleId = data["particleId"] as? String ?? "none"
        self.soundId = data["soundId"] as? String ?? "none"
        
        // Timestamp를 Date로 변환
        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()  // 기본값
        }
        
        self.votes = data["votes"] as? Int ?? 0
    }
}
