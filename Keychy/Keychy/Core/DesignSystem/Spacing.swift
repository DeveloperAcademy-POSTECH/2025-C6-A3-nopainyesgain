//
//  Spacing.swift
//  KeytschPrototype
//
//  앱 전체에서 사용하는 간격 시스템 (8pt Grid)
//
//  사용법:
//  VStack(spacing: Spacing.md) { ... }
//  .padding(Spacing.padding)
//
//  수정법:
//  1. 값 변경: static let md: CGFloat = 16 → 20
//  2. 새 간격 추가: static let custom: CGFloat = 14
//  3. 8의 배수로 유지하는 것이 일관성에 좋음 (4, 8, 16, 24, 32...)
//

//  TODO: - 실제 디자인시스템이 추가되면 아래 내용에서 바꿔주세요!
//                                  - 길3

import SwiftUI

enum Spacing {
    // MARK: - Spacing Values (8pt Grid 기반)
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // MARK: - Semantic Spacing (의미 기반 간격)
    
    // 기본 패딩
    static let padding: CGFloat = 16
    
    // 기본 마진
    static let margin: CGFloat = 20
    
    // 요소 간 간격
    static let gap: CGFloat = 12
}
