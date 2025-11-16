//
//  StoreProduct.swift
//  Keychy
//
//  Created by rundo on 11/6/25.
//

import Foundation

/// 앱 내에서 관리할 인앱 상품 정의
enum StoreProduct: String, CaseIterable, Identifiable {
    case coin1700 = "keychyCoin1700"
    case coin3500 = "keychyCoin3500"
    case coin7500 = "keychyCoin7500"
    
    var id: String { rawValue }
    
    /// 지급할 재화 양 (게임/앱 내부 로직용)
    var coinAmount: Int {
        switch self {
        case .coin1700: return 1700
        case .coin3500: return 3500
        case .coin7500: return 7500
        }
    }
}
