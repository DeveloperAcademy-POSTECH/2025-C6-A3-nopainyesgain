//
//  DeepLinkManager.swift
//  Keychy
//
//  Created by Jini on 11/8/25.
//

import SwiftUI
import Foundation

@Observable
class DeepLinkManager {
    static let shared = DeepLinkManager()
    
    var pendingKeyringId: String?
    
    private init() {}
    
    func handleDeepLink(keyringId: String) {
        print("딥링크 저장: \(keyringId)")
        self.pendingKeyringId = keyringId
    }
    
    func consumePendingDeepLink() -> String? {
        let keyringId = pendingKeyringId
        pendingKeyringId = nil
        return keyringId
    }
    
    static func createTestLink(keyringId: String) -> URL? {
        return URL(string: "keychy://receive?keyringId=\(keyringId)")
    }
    
    // 배포용 Universal Link
    static func createUniversalLink(keyringId: String) -> URL? {
        return URL(string: "https://keychy-f6011.web.app/receive/\(keyringId)")
    }
    
    // 환경에 따라 자동 선택
    static func createShareLink(keyringId: String) -> URL? {
        return createTestLink(keyringId: keyringId)
        //return createUniversalLink(keyringId: keyringId)
    }
}
