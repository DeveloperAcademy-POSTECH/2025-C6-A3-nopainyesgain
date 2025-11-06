//
//  StoreProduct.swift
//  Keychy
//
//  Created by rundo on 11/6/25.
//

import Foundation

/// 앱 내에서 관리할 인앱 상품 정의
enum StoreProduct: String, CaseIterable, Identifiable {
    case coin100 = "keychycoin01"
    
    var id: String { rawValue }
    
    /// 앱 내부에서 표시할 이름 (로컬용)
    var title: String {
        switch self {
        case .coin100: return "치키 100개"
        }
    }
    
    /// 지급할 재화 양 (게임/앱 내부 로직용)
    var coinAmount: Int {
        switch self {
        case .coin100: return 100
        }
    }
}
