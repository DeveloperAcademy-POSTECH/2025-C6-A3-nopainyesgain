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
    @State private var selectedCategory = "전체"
    @State private var showSortSheet: Bool = false
    @State private var showRenameAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteCompleteAlert: Bool = false
    @State private var showInvenExpandAlert: Bool = false // 추후 인벤토리 확장용
    @State private var renamingCategory: String = ""
    @State private var deletingCategory: String = ""
    @State private var newCategoryName: String = ""
    
    @State private var showingMenuFor: String?
    @State private var menuPosition: CGRect = .zero
    
    private var categories: [String] {
        var allCategories = ["전체"]
        allCategories.append(contentsOf: collectionViewModel.tags)
        
        return allCategories
    }
    
    // 정렬 옵션 (최신(생성) / 오래된 / 복사된 숫자순(인기순) / 이름 ㄱㄴㄷ순
    let sortOptions = ["최신순", "오래된순", "이름순"]
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Spacing.gap),
        GridItem(.flexible(), spacing: Spacing.gap)
    ]
    
    // TODO: 파이어베이스 연결해서 내 키링 불러오기
    private var myKeyrings: [Keyring] {
        var keyrings = collectionViewModel.keyring
        
        // 카테고리 필터링
        if selectedCategory != "전체" {
            keyrings = keyrings.filter { $0.tags.contains(selectedCategory) }
        }
        
        return keyrings
    }
    
    var body: some View {
        ZStack {
            VStack {
                headerSection
                    .padding(.horizontal, Spacing.margin)
                    .padding(.top, Spacing.padding)
                
                tagSection
                    .padding(.horizontal, Spacing.xs)
                
                collectionSection
                    .padding(.horizontal, Spacing.padding)
            }
            .ignoresSafeArea()
            
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
                    tagName: $newCategoryName,
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showRenameAlert = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            newCategoryName = ""
                        }
                    },
                    onConfirm: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showRenameAlert = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            renameCategory()
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
            
//            if showInvenExpandAlert {
//                Color.black20
//                    .ignoresSafeArea()
//                
//                // 추가 예정
//            }
            
        }
        .sheet(isPresented: $showSortSheet) {
            sortSheet
        }
        .onAppear {
            fetchUserData()
        }
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
    // TODO: 디자인 확정되면 반영
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


// MARK: - Header Section
extension CollectionView {
    private var headerSection: some View {
        HStack(spacing: 0) {
            Text("보관함")
                .typography(.suit32B)
                .padding(.leading, Spacing.sm)
            
            Spacer()
            
            CircleGlassButton(imageName: "Widget",
                              action: { router.push(.widgetSettingView) })
            .padding(.trailing, 10)
            
            CircleGlassButton(imageName: "Bundle",
                              action: { router.push(.bundleInventoryView) })
        }
        .padding(.top, 60)
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
    
    private var collectionSection: some View {
        VStack(spacing: 0) {
            collectionHeader
            
            if collectionViewModel.keyring.isEmpty {
                emptyview
            }
            else {
                collectionGridView
            }
        }
        //.padding(.top, Spacing.xs)
        .padding(.horizontal, Spacing.xs)
    }
    
    private var emptyview: some View {
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
            }) {
                Image("InvenPlus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
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
    
    private var collectionGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(myKeyrings, id: \.name) { keyring in
                    collectionCell(keyring: keyring)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.top, 10)
        .scrollIndicators(.hidden)
    }
    
    private func collectionCell(keyring: Keyring) -> some View {
        Button(action: {
            router.push(.collectionKeyringDetailView(keyring))
        }) {
            VStack {
                CollectionCellView(keyring: keyring)
                    .frame(width: 175, height: 233)
                    .cornerRadius(10)
                    .padding(.bottom, 10)
                
                Text("\(keyring.name) 키링")
                    .typography(.suit14SB18)
                    .foregroundColor(.black100)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 175, height: 261)
    }
}

// MARK: - Preview
#Preview {
    CollectionView(router: NavigationRouter<CollectionRoute>(), collectionViewModel: CollectionViewModel())
}
