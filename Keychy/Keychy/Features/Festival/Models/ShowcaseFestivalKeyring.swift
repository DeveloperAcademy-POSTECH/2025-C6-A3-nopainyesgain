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
    var authorId: String
    var bodyImageURL: String
    var gridIndex: Int
    var isEditing: Bool
    var keyringId: String
    var memo: String
    var particleid: String
    var soundId: String
    var votes: Int

    init(id: String = UUID().uuidString,
         authorId: String = "",
         bodyImageURL: String = "",
         gridIndex: Int = 0,
         isEditing: Bool = false,
         keyringId: String = "none",
         memo: String = "none",
         particleid: String = "none",
         soundId: String = "none",
         votes: Int = 0) {
        self.id = id
        self.authorId = authorId
        self.bodyImageURL = bodyImageURL
        self.gridIndex = gridIndex
        self.isEditing = isEditing
        self.keyringId = keyringId
        self.memo = memo
        self.particleid = particleid
        self.soundId = soundId
        self.votes = votes
    }

    /// Firestore 문서에서 초기화
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        self.id = document.documentID
        self.authorId = data["authorId"] as? String ?? ""
        self.bodyImageURL = data["bodyImageURL"] as? String ?? ""
        self.gridIndex = data["gridIndex"] as? Int ?? 0
        self.isEditing = data["isEditing"] as? Bool ?? false
        self.keyringId = data["keyringId"] as? String ?? "none"
        self.memo = data["memo"] as? String ?? "none"
        self.particleid = data["particleid"] as? String ?? "none"
        self.soundId = data["soundId"] as? String ?? "none"
        self.votes = data["votes"] as? Int ?? 0
    }
}
