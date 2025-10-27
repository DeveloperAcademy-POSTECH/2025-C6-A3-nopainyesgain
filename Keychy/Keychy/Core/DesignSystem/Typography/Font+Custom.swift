//
//  Font+Custom.swift
//  KeytschPrototype
//
//  커스텀 폰트 정의 (사용자 선택 가능한 폰트)
//
//  사용법:
//  Text("Hello").font(.custom(selectedFont, size: 16))
//
//  수정법:
//  1. 새 폰트 추가:
//     - Resources/Fonts/에 .ttf 파일 추가
//     - Info.plist에 "Fonts provided by application" 등록
//     - FontFamily enum에 case 추가
//  2. 폰트명 확인:
//     Font Book 앱으로 폰트 열어서 PostScript 이름 확인
//

import SwiftUI

// MARK: - Font Family
enum FontFamily: String, CaseIterable, Identifiable {

    var id: String { rawValue }
    var fontName: String { rawValue }
    
    /// SUIT 폰트
    case suitThin = "SUIT-Thin"
    case suitExtraLight = "SUIT-ExtraLight"
    case suitLight = "SUIT-Light"
    case suitRegular = "SUIT-Regular"
    case suitMedium = "SUIT-Medium"
    case suitSemiBold = "SUIT-SemiBold"
    case suitBold = "SUIT-Bold"
    case suitExtraBold = "SUIT-ExtraBold"
    case suitHeavy = "SUIT-Heavy"
    
    /// Nanum 폰트
    case nanumBold = "NanumSquareRoundOTFB"
    case nanumExtraBold = "NanumSquareRoundOTFEB"
    case nanumLight = "NanumSquareRoundOTFL"
    case nanumRegular = "NanumSquareRoundOTFR"

    /// 화면 표시용
    var displayName: String {
        switch self {
        case .suitThin: return "SUIT Thin"
        case .suitExtraLight: return "SUIT ExtraLight"
        case .suitLight: return "SUIT Light"
        case .suitRegular: return "SUIT Regular"
        case .suitMedium: return "SUIT Medium"
        case .suitSemiBold: return "SUIT SemiBold"
        case .suitBold: return "SUIT Bold"
        case .suitExtraBold: return "SUIT ExtraBold"
        case .suitHeavy: return "SUIT Heavy"
        case .nanumBold: return "나눔 볼드"
        case .nanumExtraBold: return "나눔 엑스트라볼드"
        case .nanumLight: return "나눔 라이트"
        case .nanumRegular: return "나눔 레귤러"
        }
    }
}

extension Font {
    /// 커스텀 폰트 적용 (사용자 선택 & 디자인 시스템 공통)
    static func custom(_ family: FontFamily, size: CGFloat) -> Font {
        return Font.custom(family.fontName, size: size)
    }
}
