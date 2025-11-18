//
//  KeychyNotification.swift
//  Keychy
//
//  Created on 11/18/25.
//

import Foundation
import FirebaseFirestore

/// 키치 알림 모델
/// - 키링 선물 수락 시 발신자에게 전송되는 알림
struct KeychyNotification: Identifiable {
    let id = UUID()  // 로컬용 ID
    var documentId: String?  // Firestore 문서 ID

    /// 알림 타입 (현재는 선물 수락만 있지만 확장 가능)
    var type: KeychyNotificationType

    /// 알림 받을 사람 UID (키링 원래 소유자)
    var receiverId: String

    /// 알림 발신자 UID (선물 받은 사람)
    var senderId: String

    /// 알림 발신자 닉네임 (알림 메시지에 표시: "영희님이 선물을 수락했어요!")
    var senderNickname: String

    /// 키링 이름 (알림에 표시할 키링 정보)
    var keyringName: String

    /// 관련 PostOffice Document ID (선물 완료 화면 이동 시 사용)
    var postOfficeId: String

    /// 읽음 여부
    var isRead: Bool

    /// 알림 생성 시간
    var createdAt: Date

    // MARK: - Firestore 저장용
    func toDictionary() -> [String: Any] {
        return [
            "type": type.rawValue,
            "receiverId": receiverId,
            "senderId": senderId,
            "senderNickname": senderNickname,
            "keyringName": keyringName,
            "postOfficeId": postOfficeId,
            "isRead": isRead,
            "createdAt": Timestamp(date: createdAt)
        ]
    }

    // MARK: - Firestore DocumentSnapshot에서 초기화
    init?(documentId: String, data: [String: Any]) {
        guard let typeString = data["type"] as? String,
              let type = KeychyNotificationType(rawValue: typeString),
              let receiverId = data["receiverId"] as? String,
              let senderId = data["senderId"] as? String,
              let senderNickname = data["senderNickname"] as? String,
              let keyringName = data["keyringName"] as? String,
              let postOfficeId = data["postOfficeId"] as? String,
              let isRead = data["isRead"] as? Bool,
              let createdTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }

        self.documentId = documentId
        self.type = type
        self.receiverId = receiverId
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.keyringName = keyringName
        self.postOfficeId = postOfficeId
        self.isRead = isRead
        self.createdAt = createdTimestamp.dateValue()
    }

    // MARK: - 일반 초기화 (코드에서 알림 생성 시 사용)
    init(
        type: KeychyNotificationType,
        receiverId: String,
        senderId: String,
        senderNickname: String,
        keyringName: String,
        postOfficeId: String,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.documentId = nil  // 새 알림이므로 아직 문서 ID 없음
        self.type = type
        self.receiverId = receiverId
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.keyringName = keyringName
        self.postOfficeId = postOfficeId
        self.isRead = isRead
        self.createdAt = createdAt
    }
}

/// 키치 알림 타입 (확장 가능)
enum KeychyNotificationType: String {
    /// 선물 수락 알림
    case giftAccepted = "giftAccepted"

    // 향후 추가 가능한 타입들:
    // case friendRequest = "friendRequest"
    // case bundleShared = "bundleShared"
}

// MARK: - KeychyNotification Extensions
extension KeychyNotification {
    /// 알림 메시지 생성
    var message: String {
        switch type {
        case .giftAccepted:
            return "님이 선물을 수락했어요!"
        }
    }

    /// 상대 시간 표시 (예: "방금", "5분 전", "2시간 전")
    var relativeTimeString: String {
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)

        if interval < 60 {
            return "방금"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)분 전"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)시간 전"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)일 전"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM월 dd일"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: createdAt)
        }
    }
}
