//
//  WorkshopView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import FirebaseFirestore
import NukeUI

enum TemplateFilterType: String, CaseIterable {
    case image = "이미지"
    case text = "텍스트"
    case drawing = "드로잉"
}

enum CommonFilterType: String, CaseIterable {
    case cute = "귀여움"
    case simple = "심플"
    case nature = "자연"
}

struct WorkshopView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Environment(UserManager.self) private var userManager
    
    private let categories = ["KEYCHY!", "키링", "카라비너", "파티클", "사운드", "배경"]
    @State private var selectedCategory: String = "KEYCHY!"
    @State private var selectedTemplateFilter: TemplateFilterType? = nil
    @State private var selectedCommonFilter: CommonFilterType? = nil
    @State private var sortOrder: String = "최신순"
    @State private var showFilterSheet: Bool = false
    @State private var mainContentOffset: CGFloat = 0
    
    // Firebase 데이터 관련 상태 변수
    @State private var templates: [KeyringTemplate] = []
    @State private var backgrounds: [Background] = []
    @State private var carabiners: [Carabiner] = []
    @State private var particles: [Particle] = []
    @State private var sounds: [Sound] = []
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // 보유한 아이템 목록
    @State private var ownedTemplates: [KeyringTemplate] = []
    @State private var ownedBackgrounds: [Background] = []
    @State private var ownedCarabiners: [Carabiner] = []
    @State private var ownedParticles: [Particle] = []
    @State private var ownedSounds: [Sound] = []
    
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
                .background(alignment: .top){
                    Image("WorkshopBack")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            
            topTitleBar
            
            stickyHeaderSection
                .background(Color(UIColor.systemBackground))
                .clipShape(.rect(cornerRadii: .init(topLeading: 20, topTrailing: 20)))
                .offset(y: max(120, min(730, mainContentOffset - 20)))
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showFilterSheet) {
            sortSheet
        }
        .task {
            await fetchAllData()
            await loadOwnedItems()
        }
        .onChange(of: selectedCategory) { oldValue, newValue in
            // 카테고리 변경 시 필터 초기화
            selectedTemplateFilter = nil
            selectedCommonFilter = nil
        }
    }
    
    // MARK: - Firebase Methods
    
    /// 모든 데이터 가져오기
    private func fetchAllData() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await fetchTemplates() }
            group.addTask { await fetchBackgrounds() }
            group.addTask { await fetchCarabiners() }
            group.addTask { await fetchParticles() }
            group.addTask { await fetchSounds() }
        }
    }
    
    /// 템플릿 가져오기
    private func fetchTemplates() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Template")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            templates = try snapshot.documents.compactMap { document in
                try document.data(as: KeyringTemplate.self)
            }
            applySorting()
        } catch {
            errorMessage = "템플릿 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    /// 배경 가져오기
    private func fetchBackgrounds() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Background")
                .getDocuments()
            
            backgrounds = try snapshot.documents.compactMap { document in
                try document.data(as: Background.self)
            }
            applySorting()
        } catch {
            errorMessage = "배경 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    /// 카라비너 가져오기
    private func fetchCarabiners() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Carabiner")
                .getDocuments()
            
            carabiners = try snapshot.documents.compactMap { document in
                try document.data(as: Carabiner.self)
            }
            applySorting()
        } catch {
            errorMessage = "카라비너 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    /// 파티클 가져오기
    private func fetchParticles() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Particle")
                .getDocuments()
            
            particles = try snapshot.documents.compactMap { document in
                try document.data(as: Particle.self)
            }
            applySorting()
        } catch {
            errorMessage = "파티클 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    /// 사운드 가져오기
    private func fetchSounds() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Sound")
                .getDocuments()
            
            sounds = try snapshot.documents.compactMap { document in
                try document.data(as: Sound.self)
            }
            applySorting()
        } catch {
            errorMessage = "사운드 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Sorting Methods
    
    /// 통합 정렬 함수 - 모든 카테고리에 적용
    private func applySorting() {
        switch sortOrder {
        case "최신순":
            templates.sort { $0.createdAt > $1.createdAt }
            backgrounds.sort { $0.createdAt > $1.createdAt }
            carabiners.sort { $0.createdAt > $1.createdAt }
            particles.sort { $0.createdAt > $1.createdAt }
            sounds.sort { $0.createdAt > $1.createdAt }
        case "인기순":
            templates.sort { $0.downloadCount > $1.downloadCount }
            backgrounds.sort { $0.downloadCount > $1.downloadCount }
            carabiners.sort { $0.downloadCount > $1.downloadCount }
            particles.sort { $0.downloadCount > $1.downloadCount }
            sounds.sort { $0.downloadCount > $1.downloadCount }
        default:
            break
        }
    }
    
    // MARK: - Filtering Methods
    
    /// 필터링된 템플릿 목록
    private var filteredTemplates: [KeyringTemplate] {
        var result = templates
        
        if let filter = selectedTemplateFilter {
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
    
    /// 필터링된 배경 목록
    private var filteredBackgrounds: [Background] {
        var result = backgrounds
        
        if let filter = selectedCommonFilter {
            result = result.filter { $0.tags.contains(filter.rawValue) }
        }
        
        return result
    }
    
    /// 필터링된 카라비너 목록
    private var filteredCarabiners: [Carabiner] {
        var result = carabiners
        
        if let filter = selectedCommonFilter {
            result = result.filter { $0.tags.contains(filter.rawValue) }
        }
        
        return result
    }
    
    /// 필터링된 파티클 목록
    private var filteredParticles: [Particle] {
        var result = particles
        
        if let filter = selectedCommonFilter {
            result = result.filter { $0.tags.contains(filter.rawValue) }
        }
        
        return result
    }
    
    /// 필터링된 사운드 목록
    private var filteredSounds: [Sound] {
        var result = sounds
        
        if let filter = selectedCommonFilter {
            result = result.filter { $0.tags.contains(filter.rawValue) }
        }
        
        return result
    }
    
    // MARK: - Owned Items Methods
    
    /// 사용자가 보유한 아이템 목록 로드
    private func loadOwnedItems() async {
        guard let user = userManager.currentUser else { return }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadOwnedTemplates(user: user) }
            group.addTask { await loadOwnedBackgrounds(user: user) }
            group.addTask { await loadOwnedCarabiners(user: user) }
            group.addTask { await loadOwnedParticles(user: user) }
            group.addTask { await loadOwnedSounds(user: user) }
        }
    }
    
    private func loadOwnedTemplates(user: KeychyUser) async {
        let ownedIds = user.templates
        guard !ownedIds.isEmpty else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Template")
                .whereField(FieldPath.documentID(), in: ownedIds)
                .getDocuments()
            
            ownedTemplates = try snapshot.documents.compactMap { try $0.data(as: KeyringTemplate.self) }
        } catch {
            print("❌ Failed to load owned templates: \(error)")
        }
    }
    
    private func loadOwnedBackgrounds(user: KeychyUser) async {
        let ownedIds = user.backgrounds
        guard !ownedIds.isEmpty else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Background")
                .whereField(FieldPath.documentID(), in: ownedIds)
                .getDocuments()
            
            ownedBackgrounds = try snapshot.documents.compactMap { try $0.data(as: Background.self) }
        } catch {
            print("❌ Failed to load owned backgrounds: \(error)")
        }
    }
    
    private func loadOwnedCarabiners(user: KeychyUser) async {
        let ownedIds = user.carabiners
        guard !ownedIds.isEmpty else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Carabiner")
                .whereField(FieldPath.documentID(), in: ownedIds)
                .getDocuments()
            
            ownedCarabiners = try snapshot.documents.compactMap { try $0.data(as: Carabiner.self) }
        } catch {
            print("❌ Failed to load owned carabiners: \(error)")
        }
    }
    
    private func loadOwnedParticles(user: KeychyUser) async {
        let ownedIds = user.particleEffects
        guard !ownedIds.isEmpty else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Particle")
                .whereField(FieldPath.documentID(), in: ownedIds)
                .getDocuments()
            
            ownedParticles = try snapshot.documents.compactMap { try $0.data(as: Particle.self) }
        } catch {
            print("❌ Failed to load owned particles: \(error)")
        }
    }
    
    private func loadOwnedSounds(user: KeychyUser) async {
        let ownedIds = user.soundEffects
        guard !ownedIds.isEmpty else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("Sound")
                .whereField(FieldPath.documentID(), in: ownedIds)
                .getDocuments()
            
            ownedSounds = try snapshot.documents.compactMap { try $0.data(as: Sound.self) }
        } catch {
            print("❌ Failed to load owned sounds: \(error)")
        }
    }
    
    /// 특정 아이템을 보유하고 있는지 확인
    private func isTemplateOwned(_ template: KeyringTemplate) -> Bool {
        guard let templateId = template.id else { return false }
        return userManager.currentUser?.templates.contains(templateId) ?? false
    }
    
    private func isBackgroundOwned(_ background: Background) -> Bool {
        guard let backgroundId = background.id else { return false }
        return userManager.currentUser?.backgrounds.contains(backgroundId) ?? false
    }
    
    private func isCarabinerOwned(_ carabiner: Carabiner) -> Bool {
        guard let carabinerId = carabiner.id else { return false }
        return userManager.currentUser?.carabiners.contains(carabinerId) ?? false
    }
    
    private func isParticleOwned(_ particle: Particle) -> Bool {
        guard let particleId = particle.id else { return false }
        return userManager.currentUser?.particleEffects.contains(particleId) ?? false
    }
    
    private func isSoundOwned(_ sound: Sound) -> Bool {
        guard let soundId = sound.id else { return false }
        return userManager.currentUser?.soundEffects.contains(soundId) ?? false
    }
}

// MARK: - 상단 배너
extension WorkshopView {
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
    
    private var titleView: some View {
        Text("공방")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var coinButton: some View {
        Button {
            router.push(.coinCharge)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.pink)
                Text("\(userManager.currentUser?.coin ?? 0)")
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
    
    /// 카테고리에 따라 다른 필터바 표시
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 정렬 필터 (공통)
                FilterChip(
                    title: sortOrder,
                    isSelected: true,
                    hasDropdown: true
                ) {
                    showFilterSheet = true
                }
                
                // 카테고리별 필터
                switch selectedCategory {
                case "키링":
                    // 템플릿 필터 (이미지형, 텍스트형, 드로잉형)
                    ForEach(TemplateFilterType.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedTemplateFilter == filter
                        ) {
                            if selectedTemplateFilter == filter {
                                selectedTemplateFilter = nil
                            } else {
                                selectedTemplateFilter = filter
                            }
                        }
                    }
                    
                case "카라비너", "파티클", "사운드", "배경":
                    // 공통 필터 (귀여움, 심플, 자연)
                    ForEach(CommonFilterType.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedCommonFilter == filter
                        ) {
                            if selectedCommonFilter == filter {
                                selectedCommonFilter = nil
                            } else {
                                selectedCommonFilter = filter
                            }
                        }
                    }
                    
                default:
                    EmptyView()
                }
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - 메인 콘텐츠
extension WorkshopView {
    /// 내 창고 섹션 - 사용자 보유 키링만 표시 (카테고리 무관)
    private var myCollectionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button("내 창고 >") {
                    router.push(.myTemplate)
                }
                .font(.subheadline)
                .foregroundStyle(.black)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if ownedTemplates.isEmpty {
                        emptyOwnedView
                    } else {
                        ForEach(ownedTemplates) { template in
                            OwnedTemplateCard(template: template, router: router)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 12)
    }
    
    private var emptyOwnedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("보유한 아이템이 없습니다")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 120, height: 100)
    }
    
    /// 메인 그리드 - 카테고리별 다른 콘텐츠 표시
    private var mainContentSection: some View {
        VStack {
            if isLoading {
                ProgressView("불러오는 중...")
                    .padding(.top, 100)
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else {
                switch selectedCategory {
                case "KEYCHY!":
                    keychyContentView
                case "키링":
                    templateGridView
                case "배경":
                    backgroundGridView
                case "카라비너":
                    carabinerGridView
                case "파티클":
                    particleGridView
                case "사운드":
                    soundGridView
                default:
                    emptyContentView
                }
            }
        }
    }
    
    /// KEYCHY! 전용 콘텐츠 (빈 화면 또는 추후 추가될 콘텐츠)
    private var keychyContentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
            
            Text("KEYCHY! 콘텐츠 준비 중")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("곧 만나요!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 100)
    }
    
    /// 템플릿 그리드
    private var templateGridView: some View {
        Group {
            if filteredTemplates.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredTemplates) { template in
                        TemplateItemView(
                            template: template,
                            isOwned: isTemplateOwned(template),
                            router: router
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 100)
            }
        }
    }
    
    /// 배경 그리드
    private var backgroundGridView: some View {
        Group {
            if filteredBackgrounds.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredBackgrounds, id: \.id) { background in
                        BackgroundItemView(
                            background: background,
                            isOwned: isBackgroundOwned(background)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 100)
            }
        }
    }
    
    /// 카라비너 그리드
    private var carabinerGridView: some View {
        Group {
            if filteredCarabiners.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredCarabiners, id: \.id) { carabiner in
                        CarabinerItemView(
                            carabiner: carabiner,
                            isOwned: isCarabinerOwned(carabiner)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 100)
            }
        }
    }
    
    /// 파티클 그리드
    private var particleGridView: some View {
        Group {
            if filteredParticles.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredParticles, id: \.id) { particle in
                        ParticleItemView(
                            particle: particle,
                            isOwned: isParticleOwned(particle)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 100)
            }
        }
    }
    
    /// 사운드 그리드
    private var soundGridView: some View {
        Group {
            if filteredSounds.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredSounds, id: \.id) { sound in
                        SoundItemView(
                            sound: sound,
                            isOwned: isSoundOwned(sound)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 100)
            }
        }
    }
    
    private var emptyContentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("표시할 아이템이 없습니다")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 100)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("다시 시도") {
                Task {
                    await fetchAllData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 100)
    }
    
    /// 정렬 선택 시트
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

// MARK: - 보유 아이템 카드들

struct OwnedTemplateCard: View {
    let template: KeyringTemplate
    @Bindable var router: NavigationRouter<WorkshopRoute>
    
    var body: some View {
        Button {
            if let route = WorkshopRoute.from(string: template.id!) {
                router.push(route)
            }
        } label: {
            VStack(spacing: 8) {
                LazyImage(url: URL(string: template.thumbnailURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.isLoading {
                        ProgressView()
                    } else {
                        Color.gray.opacity(0.1)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(template.templateName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(8)
        }
        .buttonStyle(.plain)
    }
}

struct OwnedBackgroundCard: View {
    let background: Background
    
    var body: some View {
        VStack(spacing: 8) {
            LazyImage(url: URL(string: background.backgroundImage)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if state.isLoading {
                    ProgressView()
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(background.backgroundName)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(8)
    }
}

struct OwnedCarabinerCard: View {
    let carabiner: Carabiner
    
    var body: some View {
        VStack(spacing: 8) {
            LazyImage(url: URL(string: carabiner.carabinerImage)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if state.isLoading {
                    ProgressView()
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(carabiner.carabinerName)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(8)
    }
}

struct OwnedParticleCard: View {
    let particle: Particle
    
    var body: some View {
        VStack(spacing: 8) {
            LazyImage(url: URL(string: particle.thumbnail)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if state.isLoading {
                    ProgressView()
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(particle.particleName)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(8)
    }
}

struct OwnedSoundCard: View {
    let sound: Sound
    
    var body: some View {
        VStack(spacing: 8) {
            LazyImage(url: URL(string: sound.thumbnail)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if state.isLoading {
                    ProgressView()
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(sound.soundName)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(8)
    }
}

// MARK: - 그리드 아이템 뷰들

/// 템플릿 아이템
struct TemplateItemView: View {
    let template: KeyringTemplate
    var isOwned: Bool = false
    @Bindable var router: NavigationRouter<WorkshopRoute>
    
    var body: some View {
        Button {
            if let route = WorkshopRoute.from(string: template.id!) {
                router.push(route)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topLeading) {
                    LazyImage(url: URL(string: template.thumbnailURL)) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if state.isLoading {
                            Color.gray.opacity(0.3)
                                .overlay { ProgressView() }
                        } else {
                            Color.gray.opacity(0.3)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                        }
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    priceOverlay(isFree: template.isFree, price: template.price, isOwned: isOwned)
                }
                
                Text(template.templateName)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

/// 배경 아이템
struct BackgroundItemView: View {
    let background: Background
    var isOwned: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                LazyImage(url: URL(string: background.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.isLoading {
                        Color.gray.opacity(0.3)
                            .overlay { ProgressView() }
                    } else {
                        Color.gray.opacity(0.3)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                priceOverlay(isFree: background.isFree, price: background.price, isOwned: isOwned)
            }
            
            Text(background.backgroundName)
                .font(.subheadline)
                .lineLimit(1)
        }
        .buttonStyle(.plain)
    }
}

/// 카라비너 아이템
struct CarabinerItemView: View {
    let carabiner: Carabiner
    var isOwned: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                LazyImage(url: URL(string: carabiner.carabinerImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.isLoading {
                        Color.gray.opacity(0.3)
                            .overlay { ProgressView() }
                    } else {
                        Color.gray.opacity(0.3)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                priceOverlay(isFree: carabiner.isFree, price: carabiner.price, isOwned: isOwned)
            }
            
            Text(carabiner.carabinerName)
                .font(.subheadline)
                .lineLimit(1)
        }
        .buttonStyle(.plain)
    }
}

/// 파티클 아이템
struct ParticleItemView: View {
    let particle: Particle
    var isOwned: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                LazyImage(url: URL(string: particle.thumbnail)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.isLoading {
                        Color.gray.opacity(0.3)
                            .overlay { ProgressView() }
                    } else {
                        Color.gray.opacity(0.3)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                priceOverlay(isFree: particle.isFree, price: particle.price, isOwned: isOwned)
            }
            
            Text(particle.particleName)
                .font(.subheadline)
                .lineLimit(1)
        }
        .buttonStyle(.plain)
    }
}

/// 사운드 아이템
struct SoundItemView: View {
    let sound: Sound
    var isOwned: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                LazyImage(url: URL(string: sound.thumbnail)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.isLoading {
                        Color.gray.opacity(0.3)
                            .overlay { ProgressView() }
                    } else {
                        Color.gray.opacity(0.3)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                priceOverlay(isFree: sound.isFree, price: sound.price, isOwned: isOwned)
            }
            
            Text(sound.soundName)
                .font(.subheadline)
                .lineLimit(1)
        }
        .buttonStyle(.plain)
    }
}

/// 공통 가격 오버레이
private func priceOverlay(isFree: Bool, price: Int?, isOwned: Bool) -> some View {
    VStack {
        HStack {
            if isOwned {
                Text("보유")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(Capsule())
                    .padding(8)
            } else if !isFree {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.pink)
                    Text("\(price ?? 0)")
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

// MARK: - Preview
#Preview {
    WorkshopView(router: NavigationRouter<WorkshopRoute>())
}
