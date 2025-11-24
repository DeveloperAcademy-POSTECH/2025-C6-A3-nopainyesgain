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
    let thumbnailURL: String

    /// 프리뷰 URL -----> 만들기 preview에 띄울 이미지
    let previewURL: String

    /// 가이드 이미지 URL -----> 만들기 시작 전 가이드 화면에 띄울 이미지
    let guidingImageURL: String

    /// 가이드 텍스트 -----> 만들기 시작 전 가이드 화면에 띄울 안내 문구
    let guidingText: String

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

    /// 키링 바디의 연결 지점 Y 오프셋 (아크릴 스트로크 적용 시 구멍 위치)
    /// - nil이면 바디 이미지 중앙 상단(0)을 기본값으로 사용
    /// - 양수: 바디 중심에서 위로 이동 (구멍이 더 위에 있음)
    /// - 음수: 바디 중심에서 아래로 이동 (구멍이 더 아래에 있음)
    let hookOffsetY: CGFloat?
    
    let chainLength: Int?

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
            guidingImageURL: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FguidingImage.png?alt=media&token=example",
            guidingText: "인물 사진을 선택해주세요\n배경이 제거된 키링을 만들 수 있습니다",
            tags: ["이미지형"],
            price: 0,
            downloadCount: 0,
            useCount: 0,
            createdAt: Date(),
            isActive: true,
            hookOffsetY: nil,
            chainLength: 5
        )
        template.id = "AcrylicPhoto"
        return template
    }
}

