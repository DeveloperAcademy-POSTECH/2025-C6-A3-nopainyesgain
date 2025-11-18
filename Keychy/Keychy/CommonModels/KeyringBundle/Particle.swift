//
//  Particle.swift
//  Keychy
//
//  Created by rundo on 10/30/25.
//

import Foundation
import FirebaseFirestore

/// Firebase Firestore에서 가져오는 파티클 이펙트 모델
/// - Collection: particles/{particleId}
struct Particle: Identifiable, Codable, Equatable, Hashable {
    /// Document ID
    @DocumentID var id: String?
    
    /// 파티클 이름
    let particleName: String
    
    /// 파티클 설명
    let description: String
    
    /// 파티클 데이터
    let particleData: String
    
    /// 파티클 분류 태그 (ex. ["귀여움", "#키워드"])
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

    /// 무료 파티클 여부
    var isFree: Bool {
        return price == 0
    }
}
