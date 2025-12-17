//
//  CollectionView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import SpriteKit

struct CollectionView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @State var collectionViewModel: CollectionViewModel
    @Binding var shouldRefresh: Bool
    @State var userManager = UserManager.shared
    
    @State var selectedCategory = "전체"
    @State var showSortSheet: Bool = false
    @State var showRenameAlert: Bool = false
    @State var showDeleteAlert: Bool = false
    @State var showDeleteCompleteAlert: Bool = false
    @State var showInvenExpandAlert: Bool = false
    @State var showPurchaseSuccessAlert: Bool = false
    @State var showPurchaseFailAlert: Bool = false
    @State var purchaseSuccessScale: CGFloat = 0.3
    @State var purchaseFailScale: CGFloat = 0.3
    @State var invenExpandAlertScale: CGFloat = 0.3
    @State var renamingCategory: String = ""
    @State var deletingCategory: String = ""
    @State var newCategoryName: String = ""

    @State var showingMenuFor: String?
    @State var menuPosition: CGRect = .zero

    // 디버그용
    @State var showCachedImagesDebug: Bool = false
    
    // 검색 관련
    @State var showSearchBar: Bool = false
    @State var isSearching: Bool = false
    @State var searchText: String = ""
    @State var keyboardHeight: CGFloat = 0  // 키보드 높이 추적
    @FocusState var isSearchFieldFocused: Bool
    
    // TODO: 1.1.0 Release 전 인기순 추가
    let sortOptions = ["최신순", "오래된순", "이름순"]
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Spacing.gap),
        GridItem(.flexible(), spacing: Spacing.gap)
    ]
    
    var body: some View {
        ZStack {
            VStack {
                if isSearching {
                    searchModeView
                        .transition(.opacity)
                } else {
                    normalModeView
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea()
            .blur(radius: showPurchaseSuccessAlert ? 10 : 0)
            .animation(.easeInOut(duration: 0.3), value: showPurchaseSuccessAlert)
            
            // 검색바
            if showSearchBar {
                // 키보드 위치 계산
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        searchBarView
                            .padding(.bottom, keyboardHeight > 0 ?
                                     keyboardHeight - geometry.safeAreaInsets.bottom : 4)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            }
            
            alertOverlays
            
        }
        .toolbar(isSearching ? .hidden : .visible, for: .tabBar)
        .sheet(isPresented: $showSortSheet) {
            sortSheet
        }
        .onAppear {
            fetchUserData()
            setupKeyboardNotifications()
            
            // 백그라운드에서 캐시 없는 키링들 사전 캡처
            Task(priority: .utility) {
                try? await Task.sleep(for: .seconds(1))
                await precacheAllKeyrings()
            }
        }
        .onDisappear {
            removeKeyboardNotifications()
        }
        .onChange(of: shouldRefresh) { oldValue, newValue in
            if newValue {
                fetchUserData()
                shouldRefresh = false            }
        }
        // 검색바 닫을 때 정리
        .onChange(of: showSearchBar) { oldValue, newValue in
            if !newValue {
                searchText = ""
                isSearching = false
                isSearchFieldFocused = false
            }
        }
        // 텍스트 입력 감지 - 텍스트가 있으면 검색 모드 활성화
        .onChange(of: searchText) { oldValue, newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSearching = !newValue.isEmpty
            }
        }
        .sheet(isPresented: $showCachedImagesDebug) {
            CachedImagesDebugView()
        }
    }
    
    // MARK: - 사용자 데이터 정렬 시트
    private var sortSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showSortSheet = false
                } label: {
                    Image(.dismissGray600)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                Text("정렬 기준")
                    .typography(.suit17B)
                
                Spacer()
                
                Color.clear
                    .frame(width: 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            VStack(spacing: 0) {
                ForEach(sortOptions, id: \.self) { sort in
                    SortOption(
                        title: sort,
                        isSelected: collectionViewModel.selectedSort == sort
                    ) {
                        collectionViewModel.updateSortOrder(sort)
                        
                        showSortSheet = false
                    }
                }
            }
            
            Spacer()
        }
        .presentationDetents([.height(250)])
    }
}
