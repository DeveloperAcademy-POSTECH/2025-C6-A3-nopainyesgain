//
//  Background.swift
//  KeytschPrototype
//
//  Created by rundo on 10/30/25.
//

import Foundation
import FirebaseFirestore

/// Firebase Firestore에서 가져오는 배경 이미지 모델
/// - Collection: backgrounds/{backgroundId}
struct Background: Identifiable, Codable, Equatable, Hashable {
    /// Document ID
    @DocumentID var id: String?
    
    /// 배경 이름
    let backgroundName: String

    /// 배경 설명
    let description: String

    /// 배경 이미지 URL (썸네일 공통)
    let backgroundImage: String
    
    /// 배경 분류 태그 (ex. ["귀여움", "#키워드"])
    let tags: [String]
    
    /// 구매 시 필요한 코인 (0이면 무료)
    let price: Int
    
    /// 다운로드 횟수
    let downloadCount: Int
    
    /// 사용 횟수
    let useCount: Int
    
    /// 생성일
    let createdAt: Date

    /// 앱 노출 여부 (false면 앱에서 숨김)
    let isActive: Bool

    /// 무료 배경 여부
    var isFree: Bool {
        return price == 0
    }
}
