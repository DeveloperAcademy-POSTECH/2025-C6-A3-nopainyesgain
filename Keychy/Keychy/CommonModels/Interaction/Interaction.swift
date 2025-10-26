//
//  Interaction.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

enum Interaction: CaseIterable, Identifiable {
    case tap, swing
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .tap: return "탭"
        case .swing: return "흔들기"
        }
    }
    
    var systemImage: String {
        switch self {
        case .tap: return "HandTap"
        case .swing: return "HandSwing"
        }
    }
}
