//
//  CarabinerAddKeyringButton.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//
/// 카라비너에 키링 달릴 위치를 표시하는 + 버튼입니다.
import SwiftUI

struct CarabinerAddKeyringButton: View {
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 8.73)
                .fill(.black100)
                .stroke(.white, lineWidth: 1.5)
                .frame(width: 24, height: 24)
                .overlay {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
        }

    }
}
