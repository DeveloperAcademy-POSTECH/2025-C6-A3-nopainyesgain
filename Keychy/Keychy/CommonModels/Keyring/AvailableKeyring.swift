//
//  AvailableKeyring.swift
//  Keychy
//
//  Created by Rundo on 11/9/25.
//

import Foundation

/// 위젯에서 사용할 키링 메타데이터
struct AvailableKeyring: Codable, Identifiable, Hashable {
    let id: String          // Firestore documentId
    let name: String        // 키링 이름
    let imagePath: String   // App Group Container 내 이미지 경로 (파일명만 저장)
}
