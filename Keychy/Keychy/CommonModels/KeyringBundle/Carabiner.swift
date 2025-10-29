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
    
    /// 카라비너 이미지 URL (썸네일 공통)
    let carabinerImage: String
    
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
    
    /// 키링 x위치
    let keyringXPosition: CGFloat
    
    /// 키링 y위치
    let keyringYPosition: CGFloat
    
    /// 무료 카라비너 여부
    var isFree: Bool {
        return price == 0
    }
}
