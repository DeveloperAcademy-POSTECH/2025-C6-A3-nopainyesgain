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

    // TODO: - 예시임, 실제로 추가하고 수정
    case pretendard = "Pretendard-Regular"
    case pretendardBold = "Pretendard-Bold"
    case pretendardSemiBold = "Pretendard-SemiBold"
    case roboto = "Roboto-Regular"
    case robotoBold = "Roboto-Bold"
    case nanumPen = "NanumPen-Regular"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pretendard: return "프리텐다드"
        case .pretendardBold: return "프리텐다드 Bold"
        case .pretendardSemiBold: return "프리텐다드 SemiBold"
        case .roboto: return "로보토"
        case .robotoBold: return "로보토 Bold"
        case .nanumPen: return "나눔손글씨"
        }
    }

    var fontName: String { rawValue }
}

extension Font {
    /// 커스텀 폰트 적용 (사용자 선택 & 디자인 시스템 공통)
    static func custom(_ family: FontFamily, size: CGFloat) -> Font {
        return Font.custom(family.fontName, size: size)
    }
}
