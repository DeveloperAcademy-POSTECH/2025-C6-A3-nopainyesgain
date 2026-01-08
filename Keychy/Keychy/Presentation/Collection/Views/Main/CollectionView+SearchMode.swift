//
//  CollectionView+SearchMode.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

// MARK: - 검색 관련
extension CollectionView {
    // MARK: - Search Mode View
    var searchModeView: some View {
        Group {
            if collectionViewModel.hasNetworkError {
                // 네트워크 에러: 오버레이 형태
                ZStack(alignment: .top) {
                    Color.white
                        .ignoresSafeArea()

                    NoInternetView(topPadding: getSafeAreaTop() + 90, onRetry: {
                        Task {
                            guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                                print("UID를 찾을 수 없습니다")
                                return
                            }
                            await collectionViewModel.retryFetchData(userId: uid)
                        }
                    })
                    .ignoresSafeArea()

                    VStack(spacing: 10) {
                        VStack(spacing: 10) {
                            Spacer()
                                .frame(height: 60)

                            HStack {
                                Spacer()

                                Text("\(filteredKeyrings.count)개 발견됨")
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
                            .opacity(!filteredKeyrings.isEmpty ? 1 : 0)
                        }
                        .background(Color.white)

                        Spacer()
                    }
                }
            } else {
                // 정상 상태: 기존 VStack 형태
                VStack(spacing: 10) {
                    Spacer()
                        .frame(height: 60)

                    HStack {
                        Spacer()

                        Text("\(filteredKeyrings.count)개 발견됨")
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
                    .opacity(!filteredKeyrings.isEmpty ? 1 : 0)

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
        }
    }
    
    var searchCollectionSection: some View {
        VStack(spacing: 0) {
            if filteredKeyrings.isEmpty {
                searchEmptyView
            } else {
                collectionGridView(keyrings: filteredKeyrings)
            }
        }
        .padding(.horizontal, Spacing.xs)
    }
    
    var searchEmptyView: some View {
        VStack {
            Spacer()
                .frame(height: 180)
            
            Image(.emptyViewIcon)
                .resizable()
                .frame(width: 124, height: 111)
            
            Text("검색 결과가 없어요.")
                .typography(.suit15R)
                .padding(.top, 15)
            
            Spacer()
        }
        .padding(.top, 10)
        .scrollIndicators(.hidden)
    }
    
    // 검색바 뷰 - 하단에 고정되며 키보드와 함께 움직임
    var searchBarView: some View {
        HStack(spacing: 12) {
            HStack {
                Image(.searchIcon)
                    .resizable()
                    .frame(width: 28, height: 28)
                
                TextField("검색어를 입력해주세요", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.automatic)
                    .typography(.notosans16R)
                    .tint(.main500)
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
                Image(.dismiss)
                    .foregroundColor(.primary)
            }
            .frame(width: 48, height: 48)
            .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .frame(height: 48)
    }
    
    // MARK: - 검색 키워드 Highlighted Text
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
