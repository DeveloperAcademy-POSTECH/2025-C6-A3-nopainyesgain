//
//  CollectionViewModel+Filter.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

extension CollectionViewModel {
    // MARK: - 카테고리 필터링
    // 카테고리 목록 반환
    func getCategories() -> [String] {
        var allCategories = ["전체"]
        allCategories.append(contentsOf: tags)
        return allCategories
    }
    
    // 카테고리로 키링 필터링
    func filterKeyrings(by category: String) -> [Keyring] {
        guard category != "전체" else { return keyring }
        return keyring.filter { $0.tags.contains(category) }
    }
    
    
    // MARK: - 검색 키워드 필터링
    // 검색어로 키링 필터링 (이름 + 메모)
    func searchKeyrings(keyword: String) -> [Keyring] {
        guard !keyword.isEmpty else { return keyring }
        
        return keyring.filter { keyring in
            let nameMatch = keyring.name.localizedCaseInsensitiveContains(keyword)
            let memoMatch = keyring.memo?.localizedCaseInsensitiveContains(keyword) ?? false
            return nameMatch || memoMatch
        }
    }
}
