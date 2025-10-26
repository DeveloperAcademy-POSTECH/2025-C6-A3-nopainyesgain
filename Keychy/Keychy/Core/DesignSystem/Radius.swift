//
//  Radius.swift
//  KeytschPrototype
//
//  앱 전체에서 사용하는 모서리 반경 시스템
//
//  사용법:
//  RoundedRectangle(cornerRadius: Radius.card)
//  .cornerRadius(Radius.button)
//
//  수정법:
//  1. 값 변경: static let md: CGFloat = 12 → 10
//  2. 새 반경 추가: static let custom: CGFloat = 15
//  3. 4의 배수로 유지하는 것이 일관성에 좋음 (4, 8, 12, 16, 20...)
//

//  TODO: - 실제 디자인시스템이 추가되면 아래 내용에서 바꿔주세요!
//                                  - 길3

import SwiftUI

enum Radius {
    // MARK: - Corner Radius Values (기본 반경)
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20

    // MARK: - Semantic Radius (의미 기반 반경)
    
    // 버튼 모서리
    static let button: CGFloat = 10
    
    // 카드 모서리
    static let card: CGFloat = 12
    
    // 모달 모서리
    static let modal: CGFloat = 20
}
