//
//  View+Extension.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import UIKit
import SwiftUI

extension View {
    /// 아무 곳 터치 시, 키보드 창 내립니다.
    func dismissKeyboardOnTap() -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture {
            #if canImport(UIKit)
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            #endif
            }
    }
    
    /// 키보드 창이 내려가는 메서드 입니다.
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
