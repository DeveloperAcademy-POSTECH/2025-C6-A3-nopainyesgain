//
//  PopupManager.swift
//  Keychy
//
//  Created by Jini on 11/9/25.
//

import SwiftUI

// 팝업 뒷배경 딤처리용 (얼마든지 수정 가능)
@Observable
class PopupManager {
    static let shared = PopupManager()
    
    var isDimmed: Bool = false
    
    private init() {}
    
    func showDim() {
        isDimmed = true
    }
    
    func hideDim() {
        isDimmed = false
    }
}
