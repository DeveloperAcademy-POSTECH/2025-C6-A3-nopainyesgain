//
//  PostOffice.swift
//  Keychy
//
//  Created by Jini on 11/9/25.
//

import SwiftUI
import FirebaseFirestore

struct PostOffice: Codable {
    @DocumentID var id: String?
    
    let senderId: String // 발신자
    let receiverId: String? // 수신자
    
    let keyringId: String // 보내는 키링 아이디
    let shareLink: String // 공유 링크
    
    let createdAt: Date // 포장 시간
    let endedAt: Date? // 수령시간
    
    init?(documentId: String, data: [String: Any]) {
        guard let senderId = data["senderId"] as? String,
              let keyringId = data["keyringId"] as? String,
              let shareLink = data["shareLink"] as? String,
              let createdTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.senderId = senderId
        self.receiverId = data["receiverId"] as? String
        self.keyringId = keyringId
        self.shareLink = shareLink
        self.createdAt = createdTimestamp.dateValue()
        
        if let endedTimestamp = data["endedAt"] as? Timestamp {
            self.endedAt = endedTimestamp.dateValue()
        } else {
            self.endedAt = nil
        }
    }
}
