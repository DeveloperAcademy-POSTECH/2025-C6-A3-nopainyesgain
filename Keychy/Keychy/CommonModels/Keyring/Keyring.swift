//
//  Keyring.swift
//  KeytschPrototype
//
//  Created by rundo on 10/16/25.
//

import SwiftUI
import Foundation

// TODO: - 바디, 체인, 링타입 추가 필요함
struct Keyring: Identifiable, Equatable, Hashable {
    let id = UUID()
    
    var name: String
    var bodyImage: String
    var soundId: String
    var particleId: String
    var memo: String?
    var tags: [String]
    var createdAt: Date
    var authorId: String
    var copyCount: Int
    var history: [String]?
    var selectedTemplate: String
    var selectedRing: String
    var selectedChain: String
    var isEditable: Bool
    var isPackaged: Bool
    var originalId: String?
    var chainLength: Int
}
