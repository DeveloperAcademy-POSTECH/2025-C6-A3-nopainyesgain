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

    /// 앱 노출 여부 (관리자용이라고 보면됨. -> false면 앱에서 숨김)
    let isActive: Bool

    /// 무료 템플릿 여부
    var isFree: Bool {
        return price == nil || price == 0
    }
}

