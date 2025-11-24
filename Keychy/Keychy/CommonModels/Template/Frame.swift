//
//  Frame.swift
//  Keychy
//
//  폴라로이드 프레임 모델
//

import Foundation
import FirebaseFirestore

struct Frame: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var frameURL: String
    var name: String
    var thumbnailURL: String
    var type: String?       // SpeechBubble 프레임 타입 (A, B, C)
    var order: Int?         // 정렬 순서
    var textOffsetY: CGFloat?  // SpeechBubble 텍스트 Y 오프셋

    enum CodingKeys: String, CodingKey {
        case id
        case frameURL
        case name
        case thumbnailURL
        case type
        case order
        case textOffsetY
    }
}
