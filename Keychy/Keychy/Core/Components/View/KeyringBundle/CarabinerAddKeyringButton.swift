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
    var hasKeyring: Bool
    var action: () -> Void
    var secondAction: () -> Void
    
    var body: some View {
        Button {
            if hasKeyring {
                // 이미 키링이 있는 버튼은 캡슐 버튼 띄움
                secondAction()
            } else {
                // 키링 없는 버튼은 바로 시트 띄움
                action()
            }
        } label: {
            hasKeyring ? Image(.deleteAddedKeyringButton) : Image(.addKeyringButton)
        }

    }
}
