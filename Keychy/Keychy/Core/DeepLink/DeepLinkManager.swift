//
//  DeepLinkManager.swift
//  Keychy
//
//  Created by Jini on 11/8/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

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
    
    private let db = Firestore.firestore()
    
    func handleDeepLink(postOfficeId: String, type: DeepLinkType) {
        print("딥링크 저장: \(postOfficeId), 타입: \(type)")
        
        // 1. Firestore에서 PostOffice 조회
        db.collection("PostOffice").document(postOfficeId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let documentTypeString = data["type"] as? String,
                  let documentType = PostOfficeType(rawValue: documentTypeString) else {
                print("존재하지 않는 링크입니다")
                // TODO: UI 상 처리 필요
                return
            }
            
            // 2. type 필드 확인
            guard let documentTypeString = data["type"] as? String,
                  let documentType = PostOfficeType(rawValue: documentTypeString) else {
                print("type 필드 없음")
                // TODO: UI 상 처리 필요
                return
            }
            
            // 3. URL 타입과 문서 타입 비교
            let isValid = self.validateLinkType(urlType: type, documentType: documentType)
            
            guard isValid else {
                print("타입 불일치 - URL: \(type), Document: \(documentType)")
                // TODO: UI 상 처리 필요
                return
            }
            
            self.pendingPostOfficeId = postOfficeId
            self.pendingDeepLinkType = type
            
            // 4. 검증 통과 → 정상 처리
            DispatchQueue.main.async {
                self.pendingPostOfficeId = postOfficeId
                self.pendingDeepLinkType = type
            }
        }
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
    
    // URL 타입과 PostOffice 타입 일치여부 검사
    private func validateLinkType(urlType: DeepLinkType, documentType: PostOfficeType) -> Bool {
        switch urlType {
        case .receive: return documentType == .receive
        case .collect: return documentType == .collect
        case .notification: return true
        }
    }
}
