//
//  KeyringTemplate.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/25/25.
//

import Foundation
import FirebaseFirestore

/// Firebase Firestore에서 가져오는 키링 템플릿 모델
/// - Collection: templates/{templateId}
/// - 사용자별 구매/소유 상태는 별도로 관리 (users/{userId}/purchasedTemplates)
struct KeyringTemplate: Identifiable, Codable, Equatable, Hashable {
    /// Document ID
    @DocumentID var id: String?

    /// 템플릿 이름 (ex. "아크릴 키링")
    let templateName: String

    /// 템플릿 설명
    let description: String

    /// 이 템플릿에서 제공하는 인터랙션 ID 리스트
    /// ex. ["tap", "swing" .....]
    let interactions: [String]

    /// 썸네일 이미지 URL -----> 공방 카탈로그용
    let thumbnail: String

    /// 프리뷰 URL -----> 만들기 preview에 띄울 이미지
    let preview: String

    /// 템플릿 분류 태그 (ex. ["이미지형", "텍스트형", "귀여움"])
    let tags: [String]

    /// 구매 시 필요한 코인 (nil이면 무료, 있으면 유료)
    let price: Int?

    /// 다운로드 횟수
    let downloadCount: Int

    /// 사용 횟수
    let useCount: Int

    /// 생성일
    let createdAt: Date

    /// 무료 템플릿 여부
    var isFree: Bool {
        return price == nil || price == 0
    }
}

// MARK: - Mock Data
extension KeyringTemplate {
    static var mock: KeyringTemplate {
        var template = KeyringTemplate(
            templateName: "아크릴 키링",
            description: "투명한 아크릴에 사진을 담아 만드는 키링",
            interactions: ["drum", "shutter", "fire"],
            thumbnail: "acrylic_thumbnail",
            preview: "acrylic_preview",
            tags: ["이미지형", "귀여움"],
            price: 500,
            downloadCount: 1234,
            useCount: 5678,
            createdAt: Date()
        )
        template.id = "acrylic_photo"
        return template
    }

    static var mockFree: KeyringTemplate {
        var template = KeyringTemplate(
            templateName: "기본 키링",
            description: "무료로 제공되는 기본 키링",
            interactions: ["bell"],
            thumbnail: "basic_thumbnail",
            preview: "basic_preview",
            tags: ["무료", "기본"],
            price: nil,
            downloadCount: 9999,
            useCount: 12345,
            createdAt: Date()
        )
        template.id = "basic_keyring"
        return template
    }
}
