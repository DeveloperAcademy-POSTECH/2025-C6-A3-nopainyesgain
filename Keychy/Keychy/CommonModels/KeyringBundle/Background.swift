//
//  Background.swift
//  Keychy
//
//  Created by 김서현 on 10/27/25.
//

import Foundation

struct Background: Identifiable, Equatable, Hashable {
    let id = UUID()
    var backgroundName: String
    var backgroundId: String
    var backgroundImage: String
    var tags: [String]
    /// state: 무료(0) / 구매 전(1) / 보유 중(2)
    var state: Int
    var price: Int
    var downloadCount: Int
    var useCount: Int
    var createdAt: Date
}
