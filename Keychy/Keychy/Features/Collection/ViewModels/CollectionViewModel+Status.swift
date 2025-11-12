//
//  CollectionViewModel+Status.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - 키링 상태에 따른 처리 관련
enum KeyringStatus {
    case normal
    case packaged
    case published
    
    var overlayInfo: (String)? {
        switch self {
        case .normal:
            return nil
        case .packaged:
            return ("선물 수락 대기 중")
        case .published:
            return ("페스티벌 출품 중")
        }
    }
}

extension CollectionViewModel {
    // MARK: - 인벤토리 용량 확인
    func checkInventoryCapacity(userId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("User")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(false)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let keyrings = data["keyrings"] as? [String],
                      let maxKeyringCount = data["maxKeyringCount"] as? Int else {
                    completion(false)
                    return
                }
                
                let currentCount = keyrings.count
                print("보관함 상태: \(currentCount)/\(maxKeyringCount)")
                
                // 여유 공간 있는지 확인
                let hasSpace = currentCount < maxKeyringCount
                completion(hasSpace)
            }
    }
}


extension Keyring {
    var status: KeyringStatus {
        if isPackaged {
            return .packaged
        }
        
        // 출품여부
//        if isPublished {
//            return .published
//        }
        
        return .normal
    }
}
