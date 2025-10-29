//
//  CollectionViewModel+Status.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI

// MARK: - 키링 상태에 따른 처리
enum KeyringStatus {
    case normal
    case packaged
    case published
    
    var overlayInfo: (String)? {
        switch self {
        case .normal:
            return nil
        case .packaged:
            return ("선물 수락 대기 중..")
        case .published:
            return ("페스티벌 출품 중..")
        }
    }
}

extension CollectionViewModel {
    
    
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
