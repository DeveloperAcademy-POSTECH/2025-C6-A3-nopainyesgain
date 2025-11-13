//
//  CollectionView+Collection.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

// MARK: - Normal Mode View
extension CollectionView {
    var normalModeView: some View {
        VStack {
            headerSection
                .padding(.horizontal, Spacing.margin)
                .padding(.top, Spacing.padding)
            
            tagSection
                .padding(.horizontal, Spacing.xs)
            
            normalCollectionSection
                .padding(.horizontal, Spacing.padding)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if showSearchBar && !isSearching {
                isSearchFieldFocused = false
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSearchBar = false
                }
            }
        }
    }
    
    private var normalCollectionSection: some View {
        VStack(spacing: 0) {
            collectionHeader
            
            if filteredKeyrings.isEmpty {
                emptyView
            } else {
                collectionGridView(keyrings: filteredKeyrings)
            }
        }
        .padding(.horizontal, Spacing.xs)
    }
    
    private var headerSection: some View {
        HStack(spacing: 0) {
            Text("보관함")
                .typography(.suit32B)
                .padding(.leading, Spacing.sm)

            Spacer()

            // 디버그 버튼 (빌드앱일 때만 표시)
            #if DEBUG
            Button {
                showCachedImagesDebug = true
                KeyringImageCache.shared.printAllCachedFiles()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)

                    Image(systemName: "photo.stack")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
            .padding(.trailing, 10)
            #endif
            
            CircleGlassButton(imageName: "Widget",
                              action: { router.push(.widgetSettingView) })
            .padding(.trailing, 10)

            CircleGlassButton(imageName: "bundleIcon",
                              action: { router.push(.bundleInventoryView) })
            .padding(.trailing, 10)
            
            CircleGlassButton(
                imageName: "Search",
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSearchBar = true
                    }
                    // 키보드 올리기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFieldFocused = true
                    }
                }
            )
        }
        .padding(.top, 60)
    }
    
    private var tagSection: some View {
        CategoryTabBarWithLongPress(
            categories: categories,
            selectedCategory: $selectedCategory,
            onLongPress: { category, position in
                // Long press 시 메뉴 표시
                showingMenuFor = category
                menuPosition = position
            },
            editableCategories: Set(collectionViewModel.tags) // 전체는 제외
        )
        .padding(.top, Spacing.xs)
        .padding(.horizontal, 2)
    }
    
    var emptyView: some View {
        VStack {
            Spacer().frame(height: 180)
            
            Image("EmptyViewIcon")
                .resizable()
                .frame(width: 124, height: 111)
            
            Text(selectedCategory == "전체" ? "공방에서 키링을 만들어봐요" : "해당 태그를 가진 키링이 없어요")
                .typography(.suit15R)
                .padding(.top, 15)
            
            Spacer()
        }
        .padding(.top, 10)
        .scrollIndicators(.hidden)
    }
    
    var searchEmptyView: some View {
        VStack {
            Spacer()
                .frame(height: 180)
            
            Image("EmptyViewIcon")
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
    
    var collectionHeader: some View {
        HStack(spacing: 0) {
            sortButton
            
            Spacer()
            
            // 보유한 키링 개수
            Text("\(collectionViewModel.keyring.count) / \(collectionViewModel.maxKeyringCount)")
                .typography(.suit14SB18)
                .foregroundColor(.black100)
                .padding(.trailing, 8)

            Button(action: {
                showInvenExpandAlert = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    invenExpandAlertScale = 1.0
                }
            }) {
                Image("InvenPlus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
            }
        }
    }
    
    // 정렬 버튼
    var sortButton: some View {
        Button(action: {
            showSortSheet = true
        }) {
            HStack(spacing: 2) {
                Text(collectionViewModel.selectedSort)
                    .typography(.suit14SB18)
                    .foregroundColor(.gray500)
                
                Image("ChevronDown_gray500")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, Spacing.gap)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray50)
            )
            
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func collectionGridView(keyrings: [Keyring]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(keyrings, id: \.id) { keyring in
                    collectionCell(keyring: keyring)
                }
            }
            .padding(.vertical, 4)
            .padding(.bottom, 90)
        }
        .padding(.top, 10)
        .scrollIndicators(.hidden)
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                if showSearchBar && !isSearching {
                    isSearchFieldFocused = false
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSearchBar = false
                    }
                }
                
                if showSearchBar && isSearching {
                    isSearchFieldFocused = false
                }
            }
        )
    }
    
    func collectionCell(keyring: Keyring) -> some View {
        Button(action: {
            // 검색 중일 때 키보드가 올라와 있으면 먼저 내리기
            if isSearching && isSearchFieldFocused {
                isSearchFieldFocused = false
                // 키보드가 내려간 후 네비게이션
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigateToKeyringDetail(keyring: keyring)
                }
            } else {
                navigateToKeyringDetail(keyring: keyring)
            }
        }) {
            VStack {
                CollectionCellView(keyring: keyring)
                    .frame(width: 175, height: 233)
                    .cornerRadius(10)
                
                HStack(spacing: 3) {
                    if keyring.isNew {
                        Circle()
                            .fill(.pink)
                            .frame(width: 9, height: 9)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 1.5)
                    }
                    
                    // 검색 모드일 때 하이라이트 적용
                    if isSearching && !searchText.isEmpty {
                        Text(highlightedText(text: keyring.name, keyword: searchText))
                    } else {
                        Text(keyring.name)
                            .typography(.notosans14M)
                            .foregroundColor(.black100)
                    }
                }
                

            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 175, height: 261)
    }
}
