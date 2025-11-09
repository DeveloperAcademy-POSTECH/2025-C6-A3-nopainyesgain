//
//  CarabinerType.swift
//  Keychy
//
//  Created by 김서현 on 11/9/25.
//

import Foundation

enum CarabinerType {
    case plain
    case hamburger
}

extension CarabinerType {
    static func from(_ raw: String) -> CarabinerType {
        switch raw.lowercased() {
        case "hamburger":
            return .hamburger
        case "plain":
            fallthrough
        default:
            return .plain
        }
    }
}
