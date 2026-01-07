//
//  CollectionView+NormalMode.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

// MARK: - Normal Mode View
extension CollectionView {
    // MARK: - Normal Mode View
    var normalModeView: some View {
        Group {
            if collectionViewModel.hasNetworkError {
                // 네트워크 에러: 오버레이 형태
                ZStack(alignment: .top) {
                    Color.white
                        .ignoresSafeArea()

                    NoInternetView(onRetry: {
                        Task {
                            guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                                print("UID를 찾을 수 없습니다")
                                return
                            }
                            await collectionViewModel.retryFetchData(userId: uid)
                        }
                    })
                    .ignoresSafeArea()

                    VStack {
                        VStack {
                            headerSection
                                .padding(.horizontal, Spacing.margin)
                                .padding(.top, 2)

                            tagSection
                                .padding(.horizontal, Spacing.xs)
                        }
                        .background(Color.white)

                        Spacer()
                    }
                }
            } else {
                // 정상 상태: 기존 VStack 형태
                VStack {
                    headerSection
                        .padding(.horizontal, Spacing.margin)
                        .padding(.top, 2)

                    tagSection
                        .padding(.horizontal, Spacing.xs)

                    normalCollectionSection
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
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 0) {
            Text("보관함")
                .typography(.nanum32EB)

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
                              action: {
                isSearchFieldFocused = false
                showSearchBar = false
                
                router.push(.widgetSettingView)
            }
            )
            .padding(.trailing, 10)

            CircleGlassButton(imageName: "BundleIcon",
                              action: {
                isSearchFieldFocused = false
                showSearchBar = false
                
                router.push(.bundleInventoryView)
            }
            )
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

    private var normalCollectionSection: some View {
        VStack(spacing: 0) {
            collectionHeader
                .padding(.horizontal, Spacing.padding)

            if filteredKeyrings.isEmpty {
                emptyView
            } else {
                collectionGridView(keyrings: filteredKeyrings)
            }
        }
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSearchFieldFocused = false
                    showSearchBar = false
                    
                    showInvenExpandAlert = true
                }
            }) {
                Image(.invenPlus)
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
                
                Image(.chevronDownGray500)
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
    
    var emptyView: some View {
        VStack {
            Spacer()
                .frame(height: 180)
            
            Image(.emptyViewIcon)
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
}
