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
    // isNew 필드를 고려한 정렬 적용
    func applySorting() {
        // 1. isNew가 true인 키링들과 false인 키링들 분리
        var newKeyrings = keyring.filter { $0.isNew }
        var normalKeyrings = keyring.filter { !$0.isNew }
        
        // 2. 선택된 정렬 방식을 newKeyrings와 normalKeyrings 모두에 적용
        switch selectedSort {
        case "최신순":
            newKeyrings.sort { $0.createdAt > $1.createdAt }
            normalKeyrings.sort { $0.createdAt > $1.createdAt }
            
        case "오래된순":
            newKeyrings.sort { $0.createdAt < $1.createdAt }
            normalKeyrings.sort { $0.createdAt < $1.createdAt }
            
        case "이름순":
            newKeyrings.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            normalKeyrings.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            
        case "인기순":
            newKeyrings.sort { $0.copyCount > $1.copyCount }
            normalKeyrings.sort { $0.copyCount > $1.copyCount }
        
        default:
            break
        }
        
        // 3. newKeyrings를 맨 앞에 배치하고 뒤에 normalKeyrings 추가
        keyring = newKeyrings + normalKeyrings
    }
}
