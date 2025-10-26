//
//  KeyringBundle.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import Foundation

struct KeyringBundle: Identifiable, Equatable, Hashable {
    let id = UUID()
    var name: String
    var selectedBackground: String
    var selectedCarabiner: String
    var keyrings: [String]
    var maxKeyrings: Int
    var isMain: Bool
    var createdAt: Date
}
