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
    
    /// 프리뷰 라우팅 경로 (ex: "acrylicPhotoPreview")
    let previewRoute: String

    /// 템플릿 설명
    let description: String

    /// 이 템플릿에서 제공하는 인터랙션 ID 리스트
    /// ex. ["tap", "swing" .....]
    let interactions: [String]

    /// 썸네일 이미지 URL -----> 공방 카탈로그용
    let thumbnailURL: String

    /// 프리뷰 URL -----> 만들기 preview에 띄울 이미지
    let previewURL: String

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

// MARK: - Preview용 Mock Data
extension KeyringTemplate {
    /// Firestore의 AcrylicPhoto 템플릿 데이터
    static var acrylicPhoto: KeyringTemplate {
        var template = KeyringTemplate(
            templateName: "아크릴 포토 키링",
            description: "투명한 아크릴에 사진을 담아 만드는 키링",
            interactions: ["tap", "swing"],
            thumbnailURL: "",
            previewURL: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            tags: ["이미지형"],
            price: 0,
            downloadCount: 0,
            useCount: 0,
            createdAt: Date(),
            isActive: true
        )
        template.id = "AcrylicPhoto"
        return template
    }
}

