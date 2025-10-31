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
        VStack {
            headerSection
            tagSection
            collectionSection
        }
        .padding(Spacing.padding)
        .ignoresSafeArea()
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
    
    // MARK: - 사용자 데이터 정렬 시트
    // TODO: 디자인 확정되면 반영
    private var sortSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showSortSheet = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text("정렬 기준")
                    .font(.headline)
                
                Spacer()
                
                Color.clear
                    .frame(width: 24)
            }
            .padding()
            
            Divider()
            
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
        CategoryTabBar(
            categories: categories,
            selectedCategory: $selectedCategory
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
        .padding(.top, Spacing.xs)
        .padding(.horizontal, Spacing.xs)
    }
    
    private var emptyview: some View {
        VStack {
            Spacer().frame(height: 200)
            
            Text("비었음")
                .typography(.suit14M)
            
            Image("fireworks")
                .resizable()
                .frame(width: 94, height: 94)
            
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

            Image("InvenPlus")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
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
