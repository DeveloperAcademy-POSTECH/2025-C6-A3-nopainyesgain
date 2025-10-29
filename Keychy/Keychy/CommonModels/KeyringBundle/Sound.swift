//
//  Sound.swift
//  Keychy
//
//  Created by rundo on 10/30/25.
//

import Foundation
import FirebaseFirestore

/// Firebase Firestore에서 가져오는 사운드 모델
/// - Collection: sounds/{soundId}
struct Sound: Identifiable, Codable, Equatable, Hashable {
    /// Document ID
    @DocumentID var id: String?
    
    /// 사운드 이름
    let soundName: String
    
    /// 사운드 설명
    let description: String
    
    /// 사운드 데이터 (URL 또는 파일명)
    let soundData: String
    
    /// 사운드 썸네일 이미지 URL
    let thumbnail: String
    
    /// 사운드 분류 태그 (ex. ["귀여움", "#키워드"])
    let tags: [String]
    
    /// 구매 시 필요한 코인 (0이면 무료)
    let price: Int
    
    /// 다운로드 횟수
    let downloadCount: Int
    
    /// 사용 횟수
    let useCount: Int
    
    /// 생성일
    let createdAt: Date
    
    /// 무료 사운드 여부
    var isFree: Bool {
        return price == 0
    }
}
