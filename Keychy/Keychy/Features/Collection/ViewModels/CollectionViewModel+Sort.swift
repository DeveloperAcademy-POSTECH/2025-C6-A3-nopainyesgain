//
//  CollectionViewModel+Sort.swift
//  Keychy
//
//  Created by Jini on 10/30/25.
//

import SwiftUI

// MARK: - 정렬 / 분류 처리
extension CollectionViewModel {
    // 정렬 방식 적용
    func applySorting() {
        switch selectedSort {
        case "최신순":
            keyring.sort { $0.createdAt > $1.createdAt }
            
        case "오래된순":
            keyring.sort { $0.createdAt < $1.createdAt }
            
        case "이름순":
            keyring.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            
        case "인기순":
            keyring.sort { $0.copyCount > $1.copyCount }
        
        default:
            break
        }
    }
    
}
