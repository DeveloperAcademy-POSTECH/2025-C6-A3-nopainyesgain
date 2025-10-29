//
//  WorkshopView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import FirebaseFirestore

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
    
    // Firebase 데이터 관련 상태 변수
    @State private var templates: [KeyringTemplate] = []
    @State private var isLoadingTemplates: Bool = false
    @State private var errorMessage: String? = nil
    
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
        .task {
            // View가 나타날 때 템플릿 목록 가져오기
            await fetchTemplates()
        }
    }
    
    // MARK: - Firebase Methods
    
    /// Firestore에서 템플릿 목록 가져오기
    private func fetchTemplates() async {
        isLoadingTemplates = true
        errorMessage = nil
        
        defer { isLoadingTemplates = false }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Template")
                .whereField("isActive", isEqualTo: true)  // 활성화된 템플릿만
                .getDocuments()
            
            templates = try snapshot.documents.compactMap { document in
                try document.data(as: KeyringTemplate.self)
            }
            
            // 정렬 적용
            applySorting()
            
        } catch {
            errorMessage = "템플릿 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("Error fetching templates: \(error)")
        }
    }
    
    /// 현재 선택된 정렬 기준 적용
    private func applySorting() {
        switch sortOrder {
        case "최신순":
            templates.sort { $0.createdAt > $1.createdAt }
        case "인기순":
            templates.sort { $0.downloadCount > $1.downloadCount }
        default:
            break
        }
    }
    
    /// 필터링된 템플릿 목록 반환
    private var filteredTemplates: [KeyringTemplate] {
        var result = templates
        
        // 필터 타입 적용
        if let filter = selectedFilter {
            switch filter {
            case .image:
                result = result.filter { $0.tags.contains("이미지형") }
            case .text:
                result = result.filter { $0.tags.contains("텍스트형") }
            case .drawing:
                result = result.filter { $0.tags.contains("드로잉형") }
            }
        }
        
        return result
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
    
    /// 메인 그리드 - Firestore에서 가져온 템플릿 목록 표시
    private var mainContentSection: some View {
        VStack {
            if isLoadingTemplates {
                // 로딩 중
                ProgressView("템플릿을 불러오는 중...")
                    .padding(.top, 100)
            } else if let errorMessage = errorMessage {
                // 에러 발생
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("다시 시도") {
                        Task {
                            await fetchTemplates()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 100)
            } else if filteredTemplates.isEmpty {
                // 템플릿이 없을 때
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    
                    Text("표시할 템플릿이 없습니다")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 100)
            } else {
                // 템플릿 그리드
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredTemplates) { template in
                        KeychainItem(
                            template: template,
                            category: selectedCategory
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 100)
            }
        }
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
                        applySorting()
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
    let template: KeyringTemplate
    let category: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                // 썸네일 이미지
                AsyncImage(url: URL(string: template.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 오버레이: 무료/가격 표시
                VStack {
                    HStack {
                        if !template.isFree {
                            HStack(spacing: 4) {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(.pink)
                                Text("\(template.price ?? 0)")
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(8)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
            
            // 템플릿 이름
            Text(template.templateName)
                .font(.subheadline)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview
#Preview {
    WorkshopView(router: NavigationRouter<WorkshopRoute>())
}
