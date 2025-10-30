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

// weight 뒤 숫자는 "행간크기"를 의미함.

import SwiftUI

extension Font {
    
    // MARK: - SUIT
    static let suit32B = Font.custom(.suitBold, size: 32)
    static let suit24B = Font.custom(.suitBold, size: 24)
    static let suit20B = Font.custom(.suitBold, size: 20)
    
    /// 17
    static let suit17B = Font.custom(.suitBold, size: 17)
    static let suit17SB = Font.custom(.suitSemiBold, size: 17)
    static let suit17M = Font.custom(.suitMedium, size: 17)
    
    /// 16
    static let suit16B = Font.custom(.suitBold, size: 16)
    static let suit16M = Font.custom(.suitMedium, size: 16)
    static let suit16M25 = Font.custom(.suitMedium, size: 16)
    
    /// 15
    static let suit15B25 = Font.custom(.suitBold, size: 15)
    static let suit15SB25 = Font.custom(.suitSemiBold, size: 15)
    static let suit15M25 = Font.custom(.suitMedium, size: 15)
    static let suit15R = Font.custom(.suitRegular, size: 15)
    
    /// 14
    static let suit14EB25 = Font.custom(.suitExtraBold, size: 14)
    static let suit14SB18 = Font.custom(.suitSemiBold, size: 14)
    static let suit14M = Font.custom(.suitMedium, size: 14)
    static let suit14R18 = Font.custom(.suitRegular, size: 14)
    
    /// 13
    static let suit13SB = Font.custom(.suitSemiBold, size: 13)
    static let suit13M = Font.custom(.suitMedium, size: 13)
    
    /// 12
    static let suit12M = Font.custom(.suitMedium, size: 12)
    static let suit12R25 = Font.custom(.suitRegular, size: 12)
    
    // MARK: - Nanum
    static let nanum18B = Font.custom(.nanumBold, size: 18)
    static let nanum16EB = Font.custom(.nanumExtraBold, size: 16)
    
    static let nanum15EB25 = Font.custom(.nanumExtraBold, size: 15)
    static let nanum15B25 = Font.custom(.nanumBold, size: 15)
    
    static let nanum10EB12 = Font.custom(.nanumExtraBold, size: 10)
    
    static let nanum14EB18 = Font.custom(.nanumExtraBold, size: 14)
}
