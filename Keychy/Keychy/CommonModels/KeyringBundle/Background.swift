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
    var price: Int
    var downloadCount: Int
    var useCount: Int
    var createdAt: Date
}
