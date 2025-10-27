//
//  KeychyUser.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI

struct KeychyUser: Codable, Identifiable {
    var id: String
    var nickname: String
    var email: String
    var createdAt: Date
    var maxKeyringCount: Int = 100
    var coin: Int
    var copyVoucher: Int
    var templates: [String]
    var rings: [String]
    var chains: [String]
    var soundEffects: [String]
    var particleEffects: [String]
    var backgrounds: [String]
    var carabiners: [String]
    var tags: [String]
}
