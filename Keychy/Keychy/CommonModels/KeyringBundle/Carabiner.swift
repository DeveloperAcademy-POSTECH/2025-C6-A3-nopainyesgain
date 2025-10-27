//
//  Carabiner.swift
//  Keychy
//
//  Created by 김서현 on 10/27/25.
//

import Foundation

struct Carabiner: Identifiable, Equatable, Hashable {
    let id = UUID()
    
    var carabinerName: String
    var carabinerId: String
    var carabinerImage: String
    var description: String
    var maxKeyringCount: Int
    var tags: [String]
    /// 무료(0) / 구매 전(1) / 보유 중(2)
    var state: Int
    var price: Int
    var downloadCount: Int
    var useCount: Int
    var createdAt: Date
    
    var keyringXPosition: [CGFloat]
    var keyringYPosition: [CGFloat]
}
