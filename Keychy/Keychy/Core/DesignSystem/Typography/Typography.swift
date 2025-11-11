//
//  Typography.swift
//  Keychy
//
//  앱 전체에서 사용하는 타이포그래피 스타일 (폰트 + 행간)
//
//  사용법:
//  Text("Title")
//    .typography(.suit32B)
//
//  수정법:
//  - static let 새이름 = Typography(font: .custom(.suitBold, size: 20), lineSpacing: 4)
//

import SwiftUI

struct Typography {
    let font: Font
    let lineSpacing: CGFloat

    // MARK: - SUIT
    static let suit32B = Typography(font: .custom(.suitBold, size: 32), lineSpacing: 0)
    static let suit24B = Typography(font: .custom(.suitBold, size: 24), lineSpacing: 0)
    static let suit20EB = Typography(font: .custom(.suitExtraBold, size: 20), lineSpacing: 0)
    static let suit20B = Typography(font: .custom(.suitBold, size: 20), lineSpacing: 0)
    static let suit18B = Typography(font: .custom(.suitBold, size: 18), lineSpacing: 0)

    /// 17
    static let suit17B = Typography(font: .custom(.suitBold, size: 17), lineSpacing: 0)
    static let suit17SB = Typography(font: .custom(.suitSemiBold, size: 17), lineSpacing: 0)
    static let suit17M = Typography(font: .custom(.suitMedium, size: 17), lineSpacing: 0)

    /// 16
    static let suit16B = Typography(font: .custom(.suitBold, size: 16), lineSpacing: 0)
    static let suit16M = Typography(font: .custom(.suitMedium, size: 16), lineSpacing: 0)
    static let suit16M25 = Typography(font: .custom(.suitMedium, size: 16), lineSpacing: 9)

    /// 15
    static let suit15B25 = Typography(font: .custom(.suitBold, size: 15), lineSpacing: 10)
    static let suit15SB25 = Typography(font: .custom(.suitSemiBold, size: 15), lineSpacing: 10)
    static let suit15M25 = Typography(font: .custom(.suitMedium, size: 15), lineSpacing: 10)
    static let suit15M = Typography(font: .custom(.suitMedium, size: 15), lineSpacing: 0)
    static let suit15R = Typography(font: .custom(.suitRegular, size: 15), lineSpacing: 0)

    /// 14
    static let suit14EB25 = Typography(font: .custom(.suitExtraBold, size: 14), lineSpacing: 11)
    static let suit14SB18 = Typography(font: .custom(.suitSemiBold, size: 14), lineSpacing: 4)
    static let suit14M = Typography(font: .custom(.suitMedium, size: 14), lineSpacing: 0)
    static let suit14B = Typography(font: .custom(.suitBold, size: 14), lineSpacing: 0)
    static let suit14R18 = Typography(font: .custom(.suitRegular, size: 14), lineSpacing: 4)

    /// 13
    static let suit13SB = Typography(font: .custom(.suitSemiBold, size: 13), lineSpacing: 0)
    static let suit13M = Typography(font: .custom(.suitMedium, size: 13), lineSpacing: 0)

    /// 12
    static let suit12M = Typography(font: .custom(.suitMedium, size: 12), lineSpacing: 0)
    static let suit12M25 = Typography(font: .custom(.suitMedium, size: 12), lineSpacing: 10)
    static let suit12R25 = Typography(font: .custom(.suitRegular, size: 12), lineSpacing: 13)
    
    static let suit10SB = Typography(font: .custom(.suitSemiBold, size: 10), lineSpacing: 0)

    // MARK: - Nanum
    static let nanum20EB = Typography(font: .custom(.nanumExtraBold, size: 20), lineSpacing: 0)
    static let nanum18EB = Typography(font: .custom(.nanumExtraBold, size: 18), lineSpacing: 0)
    static let nanum16EB = Typography(font: .custom(.nanumExtraBold, size: 16), lineSpacing: 0)

    static let nanum15EB25 = Typography(font: .custom(.nanumExtraBold, size: 15), lineSpacing: 10)
    static let nanum15B25 = Typography(font: .custom(.nanumBold, size: 15), lineSpacing: 10)

    static let nanum14EB18 = Typography(font: .custom(.nanumExtraBold, size: 14), lineSpacing: 4)
    
    static let nanum10EB12 = Typography(font: .custom(.nanumExtraBold, size: 10), lineSpacing: 2)
    static let nanum18EB12 = Typography(font: .custom(.nanumExtraBold, size: 18), lineSpacing: 2)
    static let nanum32EB = Typography(font: .custom(.nanumExtraBold, size: 32), lineSpacing: 2)
    
    // MARK: - Pretendard
    static let pretendard16M  = Typography(font: .custom(.pretendardMedium, size: 16), lineSpacing: 0)
    
    // MARK: - NotoSans
    static let notosans10M = Typography(font: .custom(.notoSansMedium, size: 10), lineSpacing: 0)
    static let notosans14M = Typography(font: .custom(.notoSansMedium, size: 14), lineSpacing: 0)
    static let notosans15B = Typography(font: .custom(.notoSansBold, size: 15), lineSpacing: 0)
    static let notosans15M = Typography(font: .custom(.notoSansMedium, size: 15), lineSpacing: 0)
    static let notosans15R = Typography(font: .custom(.notoSansRegular, size: 15), lineSpacing: 0)
    static let notosans16R = Typography(font: .custom(.notoSansRegular, size: 16), lineSpacing: 0)
    static let notosans16R25 = Typography(font: .custom(.notoSansRegular, size: 16), lineSpacing: 9)
    static let notosans20M = Typography(font: .custom(.notoSansMedium, size: 20), lineSpacing: 0)
    static let notosans24M = Typography(font: .custom(.notoSansMedium, size: 24), lineSpacing: 0)
    
    // MARK: - Malang
    static let malang15R = Typography(font: .custom(.malangRegular, size: 15), lineSpacing: 0)
    static let malang15B = Typography(font: .custom(.malangBold, size: 15), lineSpacing: 0)
}

// MARK: - View Extension
extension View {
    func typography(_ style: Typography) -> some View {
        self
            .font(style.font)
            .lineSpacing(style.lineSpacing)
    }
}
