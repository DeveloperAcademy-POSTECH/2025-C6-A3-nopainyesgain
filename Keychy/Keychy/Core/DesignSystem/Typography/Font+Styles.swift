//
//  Font+Styles.swift
//  KeytschPrototype
//
//  앱 전체에서 사용하는 타이포그래피 스타일
//
//  사용법:
//  Text("Title")
//    .font(.heading1)
//  Text("Body")
//    .font(.body1)
//
//  수정법:
//  - 새 스타일 추가: static let 새이름 = Font.custom(.pretendard, size: 20)
//

import SwiftUI

extension Font {
    // MARK: - Head
    static let h1 = Font.custom(.suitBold, size: 32)
    static let h2 = Font.custom(.suitBold, size: 20)
    static let h3BD = Font.custom(.suitBold, size: 16)
    static let h3MD = Font.custom(.suitMedium, size: 16)
    static let h4BD = Font.custom(.suitBold, size: 17)
    static let h4SB = Font.custom(.suitSemiBold, size: 17)

    // MARK: - Body
    static let body = Font.custom(.suitMedium, size: 16)

    // MARK: - Caption
    static let caption1 = Font.custom(.suitRegular, size: 14)
    static let caption2SB = Font.custom(.suitSemiBold, size: 13)
    static let caption2MD = Font.custom(.suitMedium, size: 13)

    // MARK: - Label
    static let label1MD = Font.custom(.suitMedium, size: 15)
    static let label1SB = Font.custom(.suitSemiBold, size: 15)

    static let label2M = Font.custom(.suitMedium, size: 14)
    static let label2SB = Font.custom(.suitSemiBold, size: 14)
    static let label2EB = Font.custom(.suitExtraBold, size: 14)
    
    static let label3RG = Font.custom(.suitRegular, size: 12)
    static let label3MD = Font.custom(.suitMedium, size: 12)
}
