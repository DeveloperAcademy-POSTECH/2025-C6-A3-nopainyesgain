//
//  String+Extension.swift
//  Keychy
//
//  Created by Jini on 11/19/25.
//

import SwiftUI

// 줄바꿈 시 단어 단위로 자르기 위함
/// 사용법 : Text(memo.byCharWrapping)
extension String {
    var byCharWrapping: Self {
        map(String.init).joined(separator: "\u{200B}")
    }
}
