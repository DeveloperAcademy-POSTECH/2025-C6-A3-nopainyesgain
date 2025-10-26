//
//  Color+Keychy.swift
//  KeytschPrototype
//
//  앱 전체에서 사용하는 컬러 시스템
//
//  사용법:
//  Text("Hello").foregroundColor(.red)
//  Button("Click").background(.bgSecondary)
//
//  수정법:
//  1. Xcode에서 Assets.xcassets/Colors 폴더로 이동
//  2. 원하는 ColorSet 클릭 후 Color Picker로 색상 변경
//  3. Dark Mode 색상도 설정 가능 (Appearances 추가)
//  4. 새 컬러 추가:
//     - Assets에 New Color Set 추가
//     - 여기에 static let 새이름 = Color("ColorSet이름") 추가
//

//  TODO: - 실제 디자인시스템이 추가되면 아래 내용에서 바꿔주세요!
//                                  - 길3

import SwiftUI

extension Color {
    // MARK: - Primary Colors (브랜드 메인 컬러)
    static let red = Color("PrimaryRed")
    static let black = Color.black
    static let white = Color.white

    // MARK: - Secondary Colors (보조 컬러)
    static let gray = Color("SecondaryGray")
    static let lightGray = Color("SecondaryLightGray")

    // MARK: - Background Colors (배경 컬러)
    static let bgPrimary = Color.white
    static let bgSecondary = Color("BackgroundSecondary")
}
