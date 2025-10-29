//
//  WorkshopView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

enum FilterType: String, CaseIterable {
    case image = "이미지"
    case text = "텍스트"
    case drawing = "드로잉"
}

struct WorkshopView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    
    private let categories = ["KEYCHY!", "키링", "카라비너", "이펙트", "배경"]
    @State private var selectedCategory: String = "KEYCHY!"
    @State private var selectedFilter: FilterType? = nil
    @State private var sortOrder: String = "최신순"
    @State private var showFilterSheet: Bool = false
    @State private var mainContentOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    topBannerSection
                        .frame(height: 150)
                    
                    Spacer()
                        .frame(height:20)
                    
                    myCollectionSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    
                    VStack {
                        mainContentSection
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onChange(of: geo.frame(in: .global).minY) { oldValue, newValue in
                                            mainContentOffset = newValue
                                        }
                                }
                            )
                    }
                    .background(Color(UIColor.systemBackground))
                }
                .padding(.top, 80)
            }
            
            topTitleBar
            
            stickyHeaderSection
                .background(Color(UIColor.systemBackground))
                .clipShape(.rect(cornerRadii: .init(topLeading: 20, topTrailing: 20)))
                .offset(y: max(120, min(730, mainContentOffset - 20)))
        }
        .background(alignment: .top){
            Image("WorkshopBack")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showFilterSheet) {
            sortSheet
        }
    }
}

// MARK: - 상단 배너
extension WorkshopView {
    /// 상단 배너 영역 - 코인 버튼과 제목 표시
    private var topBannerSection: some View {
        VStack {
            HStack {
                Spacer()
                coinButton
            }
            
            Spacer()
            
            titleView
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }
    
    /// 상단 고정 타이틀바 - 스크롤 시 나타남
    private var topTitleBar: some View {
        HStack {
            titleView
            Spacer()
            coinButton
        }
        .padding(.top, 70)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(Color(UIColor.systemBackground))
        .opacity(mainContentOffset - 80 < 70 ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: mainContentOffset)
    }
    
    /// 공방 타이틀 뷰
    private var titleView: some View {
        Text("공방")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 코인 충전 버튼 - 현재 보유 코인과 충전 화면으로 이동
    private var coinButton: some View {
        Button {
            router.push(.coinCharge)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.pink)
                Text("1,800")
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - 고정 헤더
extension WorkshopView {
    /// 상단 고정 헤더 - 탭바와 필터바 포함
    private var stickyHeaderSection: some View {
        VStack(spacing: 0) {
            CategoryTabBar(
                categories: categories,
                selectedCategory: $selectedCategory
            )
            .padding(.top, 12)
            
            filterBar
        }
        .padding(.horizontal, 20)
    }
    
    /// 필터바 - 정렬 및 타입 필터 (이미지, 텍스트, 드로잉)
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: sortOrder,
                    isSelected: true,
                    hasDropdown: true
                ) {
                    showFilterSheet = true
                }
                
                ForEach(FilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        if selectedFilter == filter {
                            selectedFilter = nil
                        } else {
                            selectedFilter = filter
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - 메인 콘텐츠
extension WorkshopView {
    /// 내 창고 섹션 - 보유한 템플릿 카드 표시
    private var myCollectionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button("내 창고 >") {
                    // Action
                }
                .font(.subheadline)
                .foregroundStyle(.black)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3) { _ in
                        TemplateCard()
                    }
                }
            }
        }
        .padding(.bottom, 12)
    }
    
    /// 메인 그리드 - 아이템 목록 2열 그리드
    private var mainContentSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(0..<10) { index in
                KeychainItem(
                    hasSticker: index % 3 == 0,
                    category: selectedCategory
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 100)
    }
    
    /// 정렬 선택 시트 - 최신순/인기순 선택
    private var sortSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showFilterSheet = false
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
                ForEach(["최신순", "인기순"], id: \.self) { sort in
                    SortOption(title: sort, isSelected: sortOrder == sort) {
                        sortOrder = sort
                        showFilterSheet = false
                    }
                }
            }
            
            Spacer()
        }
        .presentationDetents([.height(200)])
    }
}

// MARK: - 보조 뷰

/// 필터 칩 - 정렬 및 필터 옵션 선택용 캡슐 버튼
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var hasDropdown: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                if hasDropdown {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.primary : Color.secondary.opacity(0.2))
            .foregroundStyle(isSelected ? Color(UIColor.systemBackground) : .primary)
            .clipShape(Capsule())
        }
    }
}

/// 정렬 옵션 - 시트 내부의 정렬 선택 항목
struct SortOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.pink)
                }
            }
            .padding()
        }
    }
}

/// 템플릿 카드 - 내 창고에 표시되는 보유 아이템 카드
struct TemplateCard: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 80, height: 80)
            
            Text("Lable")
                .font(.caption)
        }
        .padding(8)
    }
}

/// 키체인 아이템 - 공방의 메인 그리드에 표시되는 상품 카드
struct KeychainItem: View {
    let hasSticker: Bool
    let category: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack() {
                VStack {
                    HStack {
                        if hasSticker {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.pink)
                                .padding(8)
                            Spacer()
                        } else {
                            Spacer()
                        }
                        
                        Text("보유")
                    }
                    Spacer()
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Lable")
        }
    }
}

// MARK: - Preview
#Preview {
    WorkshopView(router: NavigationRouter<WorkshopRoute>())
}
