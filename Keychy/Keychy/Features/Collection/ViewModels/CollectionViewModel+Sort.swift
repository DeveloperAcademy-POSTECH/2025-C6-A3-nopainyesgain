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
        // 1. 키링 상태에 따라 분류
        var newKeyrings = keyring.filter { $0.isNew && !$0.isPackaged && !$0.isPublished }
        var normalKeyrings = keyring.filter { !$0.isNew && !$0.isPackaged && !$0.isPublished}
        var disabledKeyrings = keyring.filter { $0.isPackaged || $0.isPublished }
        
        // 2. 선택된 정렬 방식을 newKeyrings와 normalKeyrings, disabledKeyrings 모두에 적용
        switch selectedSort {
        case "최신순":
            newKeyrings.sort { $0.createdAt > $1.createdAt }
            normalKeyrings.sort { $0.createdAt > $1.createdAt }
            disabledKeyrings.sort { $0.createdAt > $1.createdAt }
            
        case "오래된순":
            newKeyrings.sort { $0.createdAt < $1.createdAt }
            normalKeyrings.sort { $0.createdAt < $1.createdAt }
            disabledKeyrings.sort { $0.createdAt < $1.createdAt }
            
        case "이름순":
            newKeyrings.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            normalKeyrings.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            disabledKeyrings.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            
        case "인기순":
            newKeyrings.sort { $0.copyCount > $1.copyCount }
            normalKeyrings.sort { $0.copyCount > $1.copyCount }
            disabledKeyrings.sort { $0.copyCount > $1.copyCount }
        
        default:
            break
        }
        
        // 3. newKeyrings를 맨 앞에 배치하고 뒤에 normalKeyrings와 disabledKeyrings 추가
        keyring = newKeyrings + normalKeyrings + disabledKeyrings
    }
}
