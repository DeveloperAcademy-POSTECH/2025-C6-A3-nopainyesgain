//
//  Font+Styles.swift
//  KeytschPrototype
//
//  앱 전체에서 사용하는 타이포그래피 스타일
//
//  사용법:
//  Text("Title").font(.heading1)
//  Text("Body").font(.body1)
//
//  수정법:
//  - 새 스타일 추가: static let 새이름 = Font.custom(.pretendard, size: 20)
//

//  TODO: - 실제 디자인시스템이 추가되면 아래 내용에서 바꿔주세요!
//                                  - 길3

import SwiftUI

extension Font {
    // MARK: - Heading Styles (제목)
    static let heading1 = Font.custom(.pretendardBold, size: 28)
    static let heading2 = Font.custom(.pretendardBold, size: 24)
    static let heading3 = Font.custom(.pretendardSemiBold, size: 20)

    // MARK: - Body Styles (본문)
    static let body1 = Font.custom(.pretendard, size: 16)
    static let body2 = Font.custom(.pretendard, size: 14)
    static let body3 = Font.custom(.pretendard, size: 12)

    // MARK: - Button Styles (버튼)
    static let buttonLarge = Font.custom(.pretendardBold, size: 18)
    static let buttonMedium = Font.custom(.pretendardSemiBold, size: 16)
    static let buttonSmall = Font.custom(.pretendardSemiBold, size: 14)

    // MARK: - Caption (캡션)
    static let caption = Font.custom(.pretendard, size: 12)
}
