//
//  PostOffice.swift
//  Keychy
//
//  Created by Jini on 11/9/25.
//

import SwiftUI
import FirebaseFirestore

enum PostOfficeType: String, Codable {
    case receive = "receive"  // 선물 수령용 (1:1, 1회만)
    case collect = "collect"  // 배포용 (불특정 다수, 무제한)
    
    /// 향후 확장 가능성을 위한 메모
    /// case trade = "trade"      // 교환 기능 추가 시
    /// case limited = "limited"  // 한정 배포 기능 추가 시
}

struct PostOffice: Codable {
    @DocumentID var id: String?
    
    let type: PostOfficeType // PostOffice 타입 (receive / collect)
    
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
        
        // type 필드 파싱
        if let typeString = data["type"] as? String,
           let type = PostOfficeType(rawValue: typeString) {
            self.type = type
        } else {
            // type 필드가 없으면 초기화 실패
            print("PostOffice 문서에 type 필드 없음: \(documentId)")
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
