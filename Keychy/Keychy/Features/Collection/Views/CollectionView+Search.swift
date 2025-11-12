//
//  CollectionView+Search.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

// MARK: - 검색 관련
extension CollectionView {
    // MARK: - Search Mode View
    var searchModeView: some View {
        VStack(spacing: 10) {
            Spacer()
                .frame(height: 60)
            
            HStack {
                Spacer()
                
                Text("\(searchedKeyrings.count)개 발견됨")
                    .typography(.suit14M)
                    .foregroundColor(.gray500)
                    .padding(.top, 22)
                    .padding(.trailing, 22)
            }
            
            HStack {
                Text("키링")
                    .typography(.suit16B)
                    .foregroundColor(.gray500)
                    .padding(.leading, 20)
                
                Spacer()
            }
            .opacity(!searchedKeyrings.isEmpty ? 1 : 0)
            
            searchCollectionSection
                .padding(.horizontal, Spacing.padding)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSearchFieldFocused {
                isSearchFieldFocused = false
            }
        }
    }
    
    var searchCollectionSection: some View {
        VStack(spacing: 0) {
            if searchedKeyrings.isEmpty {
                searchEmptyView
            } else {
                collectionGridView(keyrings: searchedKeyrings)
            }
        }
        .padding(.horizontal, Spacing.xs)
    }
    
    // 검색바 뷰 - 하단에 고정되며 키보드와 함께 움직임
    var searchBarView: some View {
        HStack(spacing: 12) {
            HStack {
                Image("SearchIcon")
                    .resizable()
                    .frame(width: 28, height: 28)
                
                TextField("검색어를 입력해주세요", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.automatic)
                    .typography(.notosans16R)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onSubmit {
                        if searchText.isEmpty {
                            isSearchFieldFocused = false
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSearchBar = false
                            }
                        }
                    }
            }
            .padding(10)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 296))
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            
            Button(action: {
                // 키보드 먼저 내리기
                isSearchFieldFocused = false
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSearchBar = false
                }
            }) {
                Image("dismiss")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            .frame(width: 48, height: 48)
            .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .frame(height: 48)
    }
    
    // MARK: - Search Logic
    var categories: [String] {
        collectionViewModel.getCategories()
    }
    
    var filteredKeyrings: [Keyring] {
        collectionViewModel.filterKeyrings(by: selectedCategory)
    }
    
    var searchedKeyrings: [Keyring] {
        collectionViewModel.searchKeyrings(keyword: searchText)
    }
    
    func highlightedText(text: String, keyword: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        guard !keyword.isEmpty else {
            return attributedString
        }
        
        attributedString.font = .notosans14M
        
        let lowerText = text.lowercased()
        let lowerKeyword = keyword.lowercased()
        
        var searchRange = lowerText.startIndex..<lowerText.endIndex
        
        while let range = lowerText.range(of: lowerKeyword, range: searchRange) {
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: lowerText.distance(from: lowerText.startIndex, to: range.lowerBound))
            let endIndex = attributedString.index(startIndex, offsetByCharacters: lowerKeyword.count)
            let attributedRange = startIndex..<endIndex
            
            attributedString[attributedRange].foregroundColor = .main500
            attributedString[attributedRange].font = .notosans14SB
            
            searchRange = range.upperBound..<lowerText.endIndex
        }
        
        return attributedString
    }
}
