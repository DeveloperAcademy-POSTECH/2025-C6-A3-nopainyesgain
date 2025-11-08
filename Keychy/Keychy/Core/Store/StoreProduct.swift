//
//  StoreProduct.swift
//  Keychy
//
//  Created by rundo on 11/6/25.
//

import Foundation

/// 앱 내에서 관리할 인앱 상품 정의
enum StoreProduct: String, CaseIterable, Identifiable {
    case coin10 = "keychycoin10"
    case coin30 = "keychycoin30"
    case coin50 = "keychycoin50"
    case coin100 = "keychycoin100"
    case coin200 = "keychycoin200"
    case coin300 = "keychycoin300"
    
    var id: String { rawValue }
    
    /// 지급할 재화 양 (게임/앱 내부 로직용)
    var coinAmount: Int {
        switch self {
        case .coin10: return 10
        case .coin30: return 30
        case .coin50: return 50
        case .coin100: return 100
        case .coin200: return 200
        case .coin300: return 300
        }
    }
}
