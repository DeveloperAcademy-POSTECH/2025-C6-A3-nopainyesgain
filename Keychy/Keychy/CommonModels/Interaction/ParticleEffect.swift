//
//  ParticleEffect.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

enum ParticleEffect: String, CaseIterable {
    case none
    case confetti
    case birthday

    var effectFileName: String {
        switch self {
        case .none: return "none"
        case .confetti: return "Confetti"
        case .birthday: return "Birthday"
        }
    }
    
    var title: String {
        switch self {
        case .none: return "없음"
        case .confetti: return "축하"
        case .birthday: return "생일"
        }
    }
}

// Lottie iOS는 After Effects Expression(JS 기반)을 지원하지 않음 -> 파일 열었을 때 json 문자로 보이지 않고 비어었음.
// 그래서 Resources에서 로티 파일 열어봤을 때 json 문자 형식으로 알록달록하게 보인다면 문제없는 로티 json 파일임.
 
