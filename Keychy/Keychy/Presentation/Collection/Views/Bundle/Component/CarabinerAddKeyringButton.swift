//
//  CarabinerAddKeyringButton.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//
/// 카라비너에 키링 달릴 위치를 표시하는 + 버튼입니다.
import SwiftUI

struct CarabinerAddKeyringButton: View {
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(.plus)
        }
        .frame(width: 30, height: 30)
        .glassEffect(.clear.interactive(), in: .circle)
    }
}
