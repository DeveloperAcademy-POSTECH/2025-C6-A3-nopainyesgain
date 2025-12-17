//
//  CollectionViewModel+Sort.swift
//  Keychy
//
//  Created by Jini on 10/30/25.
//

import SwiftUI

extension CollectionViewModel {
    // MARK: - 정렬 방식
    // 정렬 기준 변경 및 즉시 적용
    func updateSortOrder(_ newSort: String) {
        selectedSort = newSort
        applySorting()
    }
    
    // 현재 정렬 기준으로 키링 정렬 적용
    func applySorting() {
        keyring = sortKeyrings(keyring)
    }
    
    // 키링 배열을 정렬 (새 키링 -> 일반 키링(아무 상태 없는) -> 비활성(포장or출품) 키링 순서)
    func sortKeyrings(_ keyrings: [Keyring]) -> [Keyring] {
        // 1. 상태별로 분류
        let new = keyrings.filter { $0.isNew && !$0.isPackaged && !$0.isPublished }
        let normal = keyrings.filter { !$0.isNew && !$0.isPackaged && !$0.isPublished }
        let disabled = keyrings.filter { $0.isPackaged || $0.isPublished }
        
        // 2. 각 그룹별로 정렬
        func sort(_ items: [Keyring]) -> [Keyring] {
            switch selectedSort {
            case "최신순":
                return items.sorted { $0.createdAt > $1.createdAt }
            case "오래된순":
                return items.sorted { $0.createdAt < $1.createdAt }
            case "이름순":
                return items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            case "인기순":
                return items.sorted { $0.copyCount > $1.copyCount }
            default:
                return items
            }
        }
        
        // 3. 정렬된 그룹들을 합침
        return sort(new) + sort(normal) + sort(disabled)
    }
}
