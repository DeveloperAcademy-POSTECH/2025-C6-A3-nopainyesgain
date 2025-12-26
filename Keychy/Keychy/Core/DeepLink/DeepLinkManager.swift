//
//  DeepLinkManager.swift
//  Keychy
//
//  Created by Jini on 11/8/25.
//

import SwiftUI
import Foundation

enum DeepLinkType {
    case receive      // 1:1 선물
    case collect      // 배포용
    case notification // 푸시 알림
}

@Observable
class DeepLinkManager {
    static let shared = DeepLinkManager()
    
    var pendingPostOfficeId: String?
    var pendingDeepLinkType: DeepLinkType?
    
    private init() {}
    
    func handleDeepLink(postOfficeId: String, type: DeepLinkType) {
        print("딥링크 저장: \(postOfficeId), 타입: \(type)")
        self.pendingPostOfficeId = postOfficeId
        self.pendingDeepLinkType = type
    }
    
    func consumePendingDeepLink() -> (postOfficeId: String, type: DeepLinkType)? {
        guard let postOfficeId = pendingPostOfficeId,
              let type = pendingDeepLinkType else {
            return nil
        }
        
        self.pendingPostOfficeId = nil
        self.pendingDeepLinkType = nil
        
        return (postOfficeId, type)
    }
    
    static func createTestReceiveLink(postOfficeId: String) -> URL? {
        return URL(string: "keychy://receive?postOfficeId=\(postOfficeId)")
    }
    
    static func createTestCollectLink(postOfficeId: String) -> URL? {
        return URL(string: "keychy://collect?postOfficeId=\(postOfficeId)")
    }
    
    // 배포용 Universal Link - Receive (1:1 선물)
    static func createUniversalReceiveLink(postOfficeId: String) -> URL? {
        return URL(string: "https://keychy-f6011.web.app/receive/\(postOfficeId)")
    }
    
    // 배포용 Universal Link - Collect (배포)
    static func createUniversalCollectLink(postOfficeId: String) -> URL? {
        return URL(string: "https://keychy-f6011.web.app/collect/\(postOfficeId)")
    }
    
    // 환경에 따라 자동 선택
    static func createShareLink(postOfficeId: String) -> URL? {
        //return createTestLink(keyringId: keyringId)
        return createUniversalReceiveLink(postOfficeId: postOfficeId)
    }
}
