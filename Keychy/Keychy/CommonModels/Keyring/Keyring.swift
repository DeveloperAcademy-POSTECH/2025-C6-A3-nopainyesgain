//
//  Keyring.swift
//  KeytschPrototype
//
//  Created by rundo on 10/16/25.
//

import SwiftUI
import Foundation

// TODO: - 바디, 체인, 링타입 추가 필요함
@Observable
class Keyring {
    var name = "새 키링"
    var bodyImage = Image(systemName: "photo")
    var soundId = "none"
    var particleId = "none"
    var memo = ""
    var tags: [String] = []
    var createAt = Date()
}
