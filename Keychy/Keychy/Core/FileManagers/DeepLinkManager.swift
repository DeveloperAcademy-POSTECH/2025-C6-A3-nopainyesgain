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
    
    var pendingPostOfficeId: String?
    
    private init() {}
    
    func handleDeepLink(postOfficeId: String) {
        print("딥링크 저장: \(postOfficeId)")
        self.pendingPostOfficeId = postOfficeId
    }
    
    func consumePendingDeepLink() -> String? {
        let postOfficeId = pendingPostOfficeId
        pendingPostOfficeId = nil
        return postOfficeId
    }
    
    static func createTestLink(postOfficeId: String) -> URL? {
        return URL(string: "keychy://receive?keyringId=\(postOfficeId)")
    }
    
    // 배포용 Universal Link
    static func createUniversalLink(postOfficeId: String) -> URL? {
        return URL(string: "https://keychy-f6011.web.app/receive/\(postOfficeId)")
    }
    
    // 환경에 따라 자동 선택
    static func createShareLink(postOfficeId: String) -> URL? {
        //return createTestLink(keyringId: keyringId)
        return createUniversalLink(postOfficeId: postOfficeId)
    }
}
