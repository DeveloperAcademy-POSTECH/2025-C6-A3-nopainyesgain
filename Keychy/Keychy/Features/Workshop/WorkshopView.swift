//
//  WorkshopView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

enum ShopTab: String, CaseIterable {
    case keychy = "KEYCHY!"
    case keyring = "키링"
    case carabiner = "카라비너"
    case effect = "이펙트"
    case background = "배경"
}

enum FilterType: String, CaseIterable {
    case image = "이미지"
    case text = "텍스트"
    case drawing = "드로잉"
}

struct WorkshopView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State private var selectedTab: ShopTab = .keychy
    @State private var selectedFilter: FilterType? = nil
    @State private var sortOrder: String = "최신순"
    @State private var showFilterSheet: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                VStack {
                    topBannerSection
                    
                    myCollectionSection
                }
                .padding(12)
                
                VStack() {
                    stickyHeaderSection
                    
                    mainContentSection
                }
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            }
            .background(Color.black10)
        }
        .sheet(isPresented: $showFilterSheet) {
            sortSheet
        }
    }
}

// MARK: - 상단 배너
extension WorkshopView {
    /// 상단 배너 영역 - 코인 버튼과 제목 표시
    private var topBannerSection: some View {
        
        VStack(spacing: 0) {
            HStack {
                Spacer()
                coinButton
            }
            
            Spacer()
            
            HStack {
                Text("공방")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 24)
                
                Spacer()
            }
        }
        .frame(height: 200)
        
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
            tabBar
            
            filterBar
        }
        .padding(12)
    }
    
    /// 카테고리 탭바 - KEYCHY!, 키링, 카라비너 등
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(ShopTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.top, 12)
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
    }
    
    /// 메인 그리드 - 아이템 목록 2열 그리드
    private var mainContentSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(0..<10) { index in
                KeychainItem(
                    hasSticker: index % 3 == 0,
                    tabType: selectedTab
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
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
                SortOption(title: "최신순", isSelected: sortOrder == "최신순") {
                    sortOrder = "최신순"
                    showFilterSheet = false
                }
                
                SortOption(title: "인기순", isSelected: sortOrder == "인기순") {
                    sortOrder = "인기순"
                    showFilterSheet = false
                }
            }
            
            Spacer()
        }
        .presentationDetents([.height(200)])
    }
}

// MARK: - 보조 뷰

/// 탭 버튼 - 카테고리 선택용 버튼 (선택 시 밑줄 표시)
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .pink : .primary)
                
                if isSelected {
                    Rectangle()
                        .fill(.pink)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 2)
                }
            }
        }
    }
}

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
    let tabType: ShopTab
    
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
