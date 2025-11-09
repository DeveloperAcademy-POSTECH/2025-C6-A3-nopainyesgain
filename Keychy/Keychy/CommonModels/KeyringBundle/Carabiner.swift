//
//  Carabiner.swift
//  Keychy
//
//  Created by 김서현 on 10/27/25.
//

import Foundation
import FirebaseFirestore
import CoreGraphics

/// Firebase Firestore에서 가져오는 카라비너 모델
/// - Collection: carabiners/{carabinerId}
struct Carabiner: Identifiable, Codable, Equatable, Hashable {
    /// Document ID
    @DocumentID var id: String?
    
    /// 카라비너 이름
    let carabinerName: String
    
    /// 카라비너 이미지 URL
    /// - [0] : 합체 이미지 (썸네일용)
    /// - [1] : 뒷 이미지
    /// - [2] : 앞 이미지
    let carabinerImage: [String]
    
    /// 카라비너 타입
    /// - .hamburger : 벽걸이 형
    /// - .plain : 일반 카라비너 형
    let carabinerType: String
    
    /// 카라비너 설명
    let description: String
    
    /// 걸 수 있는 키링 최대 개수
    let maxKeyringCount: Int
    
    /// 카라비너 분류 태그 (ex. ["귀여움", "#키워드"])
    let tags: [String]
    
    /// 구매 시 필요한 코인 (0이면 무료)
    let price: Int
    
    /// 다운로드 횟수
    let downloadCount: Int
    
    /// 사용 횟수
    let useCount: Int
    
    /// 생성일
    let createdAt: Date
    
    /// 키링 x위치 배열
    let keyringXPosition: [CGFloat]
    
    /// 키링 y위치 배열
    let keyringYPosition: [CGFloat]
    
    /// 무료 카라비너 여부
    var isFree: Bool {
        return price == 0
    }
    
    /// 카라비너 타입 enum
    var type: CarabinerType {
        return CarabinerType.from(carabinerType)
    }
    
    /// 뒷면(또는 단일) 카라비너 이미지 URL
    var backImageURL: String {
        switch type {
        case .hamburger:
            return carabinerImage.count > 1 ? carabinerImage[1] : ""
        case .plain:
            return carabinerImage.count > 0 ? carabinerImage[0] : ""
        }
    }
    
    /// 앞면 카라비너 이미지 URL (햄버거 타입만)
    var frontImageURL: String? {
        guard type == .hamburger, carabinerImage.count > 2 else {
            return nil
        }
        return carabinerImage[2]
    }
    
    /// 썸네일 이미지 URL
    var thumbnailImageURL: String {
        return carabinerImage.first ?? ""
    }
}
