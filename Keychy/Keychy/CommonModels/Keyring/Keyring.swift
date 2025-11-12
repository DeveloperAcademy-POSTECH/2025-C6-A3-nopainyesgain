//
//  Keyring.swift
//  KeytschPrototype
//
//  Created by rundo on 10/16/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

// TODO: - 바디, 체인, 링타입 추가 필요함
struct Keyring: Identifiable, Equatable, Hashable {
    let id = UUID()
    var firestoreId: String?  // Firestore documentId (위젯 캐시용)

    var name: String
    var bodyImage: String
    var soundId: String
    var particleId: String
    var memo: String?
    var tags: [String]
    var createdAt: Date
    var authorId: String
    var copyCount: Int
    var history: [String]?
    var selectedTemplate: String
    var selectedRing: String
    var selectedChain: String
    var isEditable: Bool
    var isPackaged: Bool
    var originalId: String?
    var chainLength: Int
    var isNew: Bool
    var senderId: String?
    var receivedAt: Date?
    
    // MARK: - Firestore 변환
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "bodyImage": bodyImage,
            "soundId": soundId,
            "particleId": particleId,
            "tags": tags,
            "createdAt": Timestamp(date: createdAt),
            "authorId": authorId,
            "copyCount": copyCount,
            "selectedTemplate": selectedTemplate,
            "selectedRing": selectedRing,
            "selectedChain": selectedChain,
            "isEditable": isEditable,
            "isPackaged": isPackaged,
            "chainLength": chainLength,
            "isNew": isNew
        ]
        
        // Optional 필드 처리
        if let memo = memo {
            dict["memo"] = memo
        }
        if let history = history {
            dict["history"] = history
        }
        if let originalId = originalId {
            dict["originalId"] = originalId
        }
        if let senderId = senderId {
            dict["senderId"] = senderId
        }
        if let receivedAt = receivedAt {
            dict["receivedAt"] = Timestamp(date: receivedAt)
        }
        
        
        return dict
    }
    
    // MARK: - Firestore DocumentSnapshot에서 초기화
    init?(documentId: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let bodyImage = data["bodyImage"] as? String,
              let soundId = data["soundId"] as? String,
              let particleId = data["particleId"] as? String,
              let tags = data["tags"] as? [String],
              let timestamp = data["createdAt"] as? Timestamp,
              let authorId = data["authorId"] as? String,
              let selectedTemplate = data["selectedTemplate"] as? String,
              let selectedRing = data["selectedRing"] as? String,
              let selectedChain = data["selectedChain"] as? String else {
            return nil
        }

        // Firestore documentId 저장 (위젯 캐시 키로 사용)
        self.firestoreId = documentId

        // 기본값이 있는 필드들
        self.name = name
        self.bodyImage = bodyImage
        self.soundId = soundId
        self.particleId = particleId
        self.tags = tags
        self.createdAt = timestamp.dateValue()
        self.authorId = authorId
        self.selectedTemplate = selectedTemplate
        self.selectedRing = selectedRing
        self.selectedChain = selectedChain

        // 기본값 제공 필드
        self.copyCount = data["copyCount"] as? Int ?? 0
        self.isEditable = data["isEditable"] as? Bool ?? true
        self.isPackaged = data["isPackaged"] as? Bool ?? false
        self.chainLength = data["chainLength"] as? Int ?? 5
        self.isNew = data["isNew"] as? Bool ?? true

        // Optional 필드
        self.memo = data["memo"] as? String
        self.history = data["history"] as? [String]
        self.originalId = data["originalId"] as? String
        self.senderId = data["senderId"] as? String
        
        if let receivedTimestamp = data["receivedAt"] as? Timestamp {
            self.receivedAt = receivedTimestamp.dateValue()
        } else {
            self.receivedAt = nil
        }
    }
    
    // MARK: - 일반 초기화 (새 키링 생성용)
    init(name: String,
         bodyImage: String,
         soundId: String,
         particleId: String,
         memo: String? = nil,
         tags: [String],
         createdAt: Date,
         authorId: String,
         selectedTemplate: String,
         selectedRing: String,
         selectedChain: String,
         originalId: String? = nil,
         chainLength: Int,
         isNew: Bool = true,
         senderId: String? = nil,
         receivedAt: Date? = nil
    ) {
        self.name = name
        self.bodyImage = bodyImage
        self.soundId = soundId
        self.particleId = particleId
        self.memo = memo
        self.tags = tags
        self.createdAt = createdAt
        self.authorId = authorId
        self.copyCount = 0
        self.history = []
        self.selectedTemplate = selectedTemplate
        self.selectedRing = selectedRing
        self.selectedChain = selectedChain
        self.isEditable = true
        self.isPackaged = false
        self.originalId = originalId
        self.chainLength = chainLength
        self.isNew = isNew
        self.senderId = senderId
        self.receivedAt = receivedAt
    }
}
