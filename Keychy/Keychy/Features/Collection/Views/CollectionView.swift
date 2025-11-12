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
    @State private var userManager = UserManager.shared
    @State private var selectedCategory = "전체"
    @State private var showSortSheet: Bool = false
    @State private var showRenameAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteCompleteAlert: Bool = false
    @State private var showInvenExpandAlert: Bool = false
    @State private var showPurchaseSuccessAlert: Bool = false
    @State private var showPurchaseFailAlert: Bool = false
    @State private var purchaseSuccessScale: CGFloat = 0.3
    @State private var purchaseFailScale: CGFloat = 0.3
    @State private var invenExpandAlertScale: CGFloat = 0.3
    @State private var renamingCategory: String = ""
    @State private var deletingCategory: String = ""
    @State private var newCategoryName: String = ""

    @State private var showingMenuFor: String?
    @State private var menuPosition: CGRect = .zero

    // 디버그용
    @State private var showCachedImagesDebug: Bool = false
    
    // 검색 관련
    @State private var showSearchBar: Bool = false
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    @State private var keyboardHeight: CGFloat = 0  // 키보드 높이 추적
    @FocusState private var isSearchFieldFocused: Bool
    
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
            
            if let menuCategory = showingMenuFor {
                Color.black20
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingMenuFor = nil // dismiss용
                    }
                
                CategoryContextMenu(
                    categoryName: menuCategory,
                    position: menuPosition,
                    onRename: {
                        showingMenuFor = nil
                        renamingCategory = menuCategory
                        newCategoryName = menuCategory
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showRenameAlert = true
                        }
                    },
                    onDelete: {
                        showingMenuFor = nil
                        deletingCategory = menuCategory
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteAlert = true
                        }
                    },
                    onDismiss: {
                        showingMenuFor = nil
                    }
                )
                .zIndex(50)
            }
            
            if showDeleteAlert || showDeleteCompleteAlert {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(99)
                
                if showDeleteAlert {
                    DeletePopup(
                        title: "[\(deletingCategory)]\n정말 삭제하시겠어요?",
                        message: "한 번 삭제하면 복구 할 수 없습니다.",
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDeleteAlert = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                deletingCategory = ""
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDeleteAlert = false
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                confirmDeleteCategory()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showDeleteCompleteAlert = true
                                }
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
                
                if showDeleteCompleteAlert {
                    DeleteCompletePopup(isPresented: $showDeleteCompleteAlert)
                        .zIndex(100)
                }
            }
            
            
            if showRenameAlert {
                Color.black20
                    .ignoresSafeArea()
                
                TagInputPopup(
                    type: .edit,
                    tagName: $newCategoryName,
                    availableTags: categories,
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showRenameAlert = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            newCategoryName = ""
                        }
                    },
                    onConfirm: {_ in 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showRenameAlert = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            renameCategory()
                            newCategoryName = ""
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
            
            if showDeleteAlert || showDeleteCompleteAlert {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(99)
                
                if showDeleteAlert {
                    DeletePopup(
                        title: "[\(deletingCategory)]\n정말 삭제하시겠어요?",
                        message: "한 번 삭제하면 복구 할 수 없습니다.",
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDeleteAlert = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                deletingCategory = ""
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDeleteAlert = false
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                confirmDeleteCategory()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showDeleteCompleteAlert = true
                                }
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
                
                if showDeleteCompleteAlert {
                    DeleteCompletePopup(isPresented: $showDeleteCompleteAlert)
                        .zIndex(100)
                }
            }
            
            if showInvenExpandAlert || showPurchaseSuccessAlert || showPurchaseFailAlert{
                Color.black20
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            invenExpandAlertScale = 0.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showInvenExpandAlert = false
                        }
                    }

                if showInvenExpandAlert {
                    PurchasePopup(
                        title: "보관함 확장 [+10]",
                        myCoin: collectionViewModel.coin,
                        price: 100,
                        scale: invenExpandAlertScale,
                        onConfirm: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                invenExpandAlertScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showInvenExpandAlert = false
                                expandInventory()
                            }
                        }
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                    .transition(.scale.combined(with: .opacity))
                }
                
                if showPurchaseSuccessAlert {
                    PurchaseSuccessPopup(isPresented: $showPurchaseSuccessAlert)
                        .zIndex(100)
                }
                
                if showPurchaseFailAlert {
                    LackPopup(
                        title: "열쇠가 부족합니다!",
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showPurchaseFailAlert = false
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showPurchaseFailAlert = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                router.push(.coinCharge)
                            }
                        }
                    )
                    .zIndex(100)
                }

            }
            
        }
        .toolbar(isSearching ? .hidden : .visible, for: .tabBar)
        .sheet(isPresented: $showSortSheet) {
            sortSheet
        }
        .onAppear {
            fetchUserData()
            setupKeyboardNotifications()
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
    
    
    // MARK: - 키보드 노티피케이션
    // 키보드 노티피케이션 설정 (키보드 높이를 감지해서 검색바 위치 조정)
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
    
    // 키보드 노티피케이션 제거
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - 사용자 데이터 로드
    private func fetchUserData() {
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
            print("UID를 찾을 수 없습니다")
            return
        }
        
        fetchUserCategories(uid: uid) {
            fetchUserKeyrings(uid: uid)
        }
    }
    
    // 키링 로드
    private func fetchUserKeyrings(uid: String) {
        collectionViewModel.fetchUserKeyrings(uid: uid) { success in
            if success {
                print("키링 로드 완료: \(collectionViewModel.keyring.count)개")
            } else {
                print("키링 로드 실패")
            }
        }
    }
    
    // 사용자 기반 데이터 로드
    private func fetchUserCategories(uid: String, completion: @escaping () -> Void) {
        collectionViewModel.fetchUserCollectionData(uid: uid) { success in
            if success {
                print("정보 로드 완료")
            } else {
                print("정보 로드 실패")
            }
            completion()
        }
    }
    
    // MARK: - 태그 관리
    private func renameCategory() {
        guard !newCategoryName.isEmpty else { return }
        
        // 기존 이름과 같으면 변경 안 함
        guard newCategoryName != renamingCategory else { return }
        
        // 이미 존재하는 태그 이름인지 확인
        if collectionViewModel.tags.contains(newCategoryName) {
            // TODO: 에러 처리 어떻게?
            return
        }
        
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
            print("UID를 찾을 수 없습니다")
            return
        }
        
        collectionViewModel.renameTag(
            uid: uid,
            oldName: renamingCategory,
            newName: newCategoryName
        ) { success in
            if success {
                if selectedCategory == renamingCategory {
                    selectedCategory = "전체"
                }
                fetchUserData()
            }
        }
        
        newCategoryName = ""
    }
    
    private func confirmDeleteCategory() {
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
            print("UID를 찾을 수 없습니다")
            return
        }
        
        collectionViewModel.deleteTag(
            uid: uid,
            tagName: deletingCategory
        ) { success in
            if success {
                if selectedCategory == deletingCategory {
                    selectedCategory = "전체"
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    fetchUserData()
                    deletingCategory = ""
                }
            } else {
                showDeleteCompleteAlert = false
                deletingCategory = ""
            }
        }
        
        deletingCategory = ""
    }
    
    // MARK: - 사용자 데이터 정렬 시트
    private var sortSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showSortSheet = false
                } label: {
                    Image("Dismiss_gray600")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                Text("정렬 기준")
                    .typography(.suit15B25)
                
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
                        collectionViewModel.selectedSort = sort
                        collectionViewModel.applySorting()
                        
                        showSortSheet = false
                    }
                }
            }
            
            Spacer()
        }
        .presentationDetents([.height(250)])
    }
}

// MARK: - Normal Mode View
extension CollectionView {
    private var normalModeView: some View {
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
            
            if filteredKeyrings.isEmpty { // 태그에 해당하는 키링이 없어요.
                emptyView
            } else {
                collectionGridView(keyrings: filteredKeyrings)
            }
        }
        .padding(.horizontal, Spacing.xs)
        //.padding(.bottom, showSearchBar ? 100 : 0)
    }
}

// MARK: - Search Mode View
extension CollectionView {
    private var searchModeView: some View {
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
    
    private var searchCollectionSection: some View {
        VStack(spacing: 0) {
            if searchedKeyrings.isEmpty {
                searchEmptyView
            } else {
                collectionGridView(keyrings: searchedKeyrings)
            }
        }
        .padding(.horizontal, Spacing.xs)
        //.padding(.bottom, showSearchBar ? 100 : 0)
    }
}

// 검색
extension CollectionView {
    private var categories: [String] {
        var allCategories = ["전체"]
        allCategories.append(contentsOf: collectionViewModel.tags)
        return allCategories
    }

    // 일반 모드: 카테고리 필터링만
    private var filteredKeyrings: [Keyring] {
        var keyrings = collectionViewModel.keyring
        
        if selectedCategory != "전체" {
            keyrings = keyrings.filter { $0.tags.contains(selectedCategory) }
        }
        
        return keyrings
    }
    
    // 검색 모드: 검색어 필터링만
    private var searchedKeyrings: [Keyring] {
        guard !searchText.isEmpty else { return collectionViewModel.keyring }
        
        return collectionViewModel.keyring.filter { keyring in
            keyring.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}


// MARK: - Header Section
extension CollectionView {
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

            CircleGlassButton(imageName: "Bundle",
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
    
    // 검색바 뷰 - 하단에 고정되며 키보드와 함께 움직임
    private var searchBarView: some View {
        HStack(spacing: 12) {
            // 검색 아이콘
            HStack {
                Image("SearchIcon")
                    .resizable()
                    .frame(width: 28, height: 28)
                
                // 검색 텍스트 필드
                TextField("검색어를 입력해주세요", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.automatic)
                    .typography(.suit15M25)
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

            // 닫기 버튼
            Button(action: {
                // 키보드 먼저 내리기
                isSearchFieldFocused = false
                
                // 애니메이션과 함께 검색바 닫기
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
}

// MARK: - Tags Section
extension CollectionView {
    
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
}

// MARK: - Collection Section
extension CollectionView {
    private var emptyView: some View {
        VStack {
            Spacer().frame(height: 180)
            
            Image("EmptyViewIcon")
                .resizable()
                .frame(width: 124, height: 111)
            
            Text("보관함이 비었어요.")
                .typography(.suit15R)
                .padding(.top, 15)
            
            Spacer()
        }
        .padding(.top, 10)
        .scrollIndicators(.hidden)
    }
    
    private var searchEmptyView: some View {
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
    
    private var collectionHeader: some View {
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
    
    // 인벤 확장
    private func expandInventory() {
        Task {
            let result = await collectionViewModel.purchaseInventoryExpansion(
                userManager: userManager,
                expansionCost: 100
            )
            
            await MainActor.run {
                switch result {
                case .success:
                    print("인벤토리 확장 성공")
                    
                    // 성공 알림 표시
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPurchaseSuccessAlert = true
                    }
                    
                    // 사용자 데이터 새로고침
                    fetchUserData()
                    
                case .insufficientCoins:
                    print("코인 부족")
                    
                    // 코인 부족 알림 표시
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPurchaseFailAlert = true
                    }
                    
                case .failed(let message):
                    print("구매 실패: \(message)")
                    
                    // 실패 알림 표시
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPurchaseFailAlert = true
                    }
                }
            }
        }
    }
    
    // 정렬 버튼
    private var sortButton: some View {
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
    
    private func collectionGridView(keyrings: [Keyring]) -> some View {
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
    
    private func highlightedText(text: String, keyword: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        guard !keyword.isEmpty else {
            return attributedString
        }
        
        // 대소문자 구분 없이 검색
        let lowerText = text.lowercased()
        let lowerKeyword = keyword.lowercased()
        
        var searchRange = lowerText.startIndex..<lowerText.endIndex
        
        while let range = lowerText.range(of: lowerKeyword, range: searchRange) {
            // AttributedString의 range로 변환
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: lowerText.distance(from: lowerText.startIndex, to: range.lowerBound))
            let endIndex = attributedString.index(startIndex, offsetByCharacters: lowerKeyword.count)
            let attributedRange = startIndex..<endIndex
            
            // 검색어 부분 스타일 변경
            attributedString[attributedRange].foregroundColor = .main500
            attributedString[attributedRange].font = .notosans14SB
            
            // 다음 검색 범위 설정
            searchRange = range.upperBound..<lowerText.endIndex
        }
        
        return attributedString
    }
    
    private func collectionCell(keyring: Keyring) -> some View {
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
                
                Text(keyring.name)
                    .typography(.notosans14M)
                    .foregroundColor(.black100)

            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 175, height: 261)
    }
    
    private func navigateToKeyringDetail(keyring: Keyring) {
        if keyring.isPackaged {
            router.push(.collectionKeyringPackageView(keyring))
        } else {
            router.push(.collectionKeyringDetailView(keyring))
        }
    }
}
