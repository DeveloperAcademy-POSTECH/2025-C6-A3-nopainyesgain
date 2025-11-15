//
//  WorkshopComponents.swift
//  Keychy
//
//  Created by rundo on 10/31/25.
//

import SwiftUI
import NukeUI
import Lottie

// MARK: - Filter Components

/// 필터 칩 버튼
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .typography(.suit14SB18)
                    .foregroundColor(isSelected ? Color(.systemBackground) : .gray500)
            }
            .padding(.horizontal, Spacing.gap)
            .padding(.vertical, Spacing.sm)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.black70 : Color.gray50)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sort Components

/// 정렬 옵션 행
struct SortOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .typography(.suit16M)
                    .foregroundColor(.black100)
                
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

/// 정렬 선택 시트
struct WorkshopSortSheet: View {
    @Binding var showSheet: Bool
    @Binding var sortOrder: String

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button {
                    showSheet = false
                } label: {
                    Image("dismiss_gray600")
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
            .padding()

            // 정렬 옵션
            VStack(spacing: 0) {
                ForEach(["최신순", "인기순"], id: \.self) { sort in
                    SortOption(
                        title: sort,
                        isSelected: sortOrder == sort
                    ) {
                        sortOrder = sort
                        showSheet = false
                    }
                }
            }

            Spacer()
        }
        .presentationDetents([.height(200)])
    }
}

// MARK: - Item Views

/// 모든 워크샵 아이템을 표시하는 통합 그리드 아이템 뷰
struct WorkshopItemView<Item: WorkshopItem>: View {
    let item: Item
    var isOwned: Bool = false
    var router: NavigationRouter<WorkshopRoute>? = nil
    var viewModel: WorkshopViewModel? = nil
    var showDeleteButton: Bool = false  // MyItemsView에서만 true

    @State private var effectManager = EffectManager.shared
    @Environment(UserManager.self) private var userManager

    var body: some View {
        Button {
            handleTap()
        } label: {
            VStack(spacing: 8) {
                // 썸네일 이미지
                thumbnailImage

                // 아이템 이름
                Text(item.name)
                    .typography(.suit14SB18)
            }
        }
        .buttonStyle(.plain)
    }

    /// 썸네일 이미지 + 가격 오버레이
    private var thumbnailImage: some View {
        ZStack(alignment: .top) {
            LazyImage(url: URL(string: item.thumbnailURL)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 175, height: itemHeight)
                        .clipped()
                } else if state.isLoading {
                    Color.gray50
                        .overlay { ProgressView() }
                } else {
                    Color.gray50
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.gray300)
                        }
                }
            }

            // 가격 오버레이
            priceOverlay(
                isFree: item.isFree,
                price: item.workshopPrice,
                isOwned: isOwned,
                item: item,
                effectManager: effectManager,
                userManager: userManager
            )
        }
        .frame(width: 175, height: itemHeight)
        .background(Color.gray50)
        .cornerRadius(10)
    }

    /// 아이템 타입에 따른 높이 계산
    private var itemHeight: CGFloat {
        if item is KeyringTemplate || item is Background {
            return 233
        } else {
            return 175
        }
    }

    /// 탭 핸들러 (키링은 바로 만들기, 나머지는 WorkshopPreview로 이동)
    private func handleTap() {
        guard let router = router else { return }

        // 키링일 경우 바로 해당 키링 Preview로 이동
        if let template = item as? KeyringTemplate,
           let templateId = template.id,
           let route = WorkshopRoute.from(string: templateId, showDeleteButton: showDeleteButton) {
            router.push(route)
        }
        // 나머지 아이템들은 WorkshopPreview로 이동
        else if let background = item as? Background {
            router.push(.workshopPreview(item: AnyHashable(background), showDeleteButton: showDeleteButton))
        } else if let carabiner = item as? Carabiner {
            router.push(.workshopPreview(item: AnyHashable(carabiner), showDeleteButton: showDeleteButton))
        } else if let particle = item as? Particle {
            router.push(.workshopPreview(item: AnyHashable(particle), showDeleteButton: showDeleteButton))
        } else if let sound = item as? Sound {
            router.push(.workshopPreview(item: AnyHashable(sound), showDeleteButton: showDeleteButton))
        }
    }
}

/// 보유한 아이템을 표시하는 작은 카드 뷰
struct CurrentUsedCard<Item: WorkshopItem>: View {
    let item: Item
    var router: NavigationRouter<WorkshopRoute>? = nil
    var viewModel: WorkshopViewModel? = nil
    var showDeleteButton: Bool = false  // MyItemsView에서만 true

    var body: some View {
        Button {
            handleTap()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    LazyImage(url: URL(string: item.thumbnailURL)) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if state.isLoading {
                            ProgressView()
                        } else {
                            Color.gray50
                        }
                    }
                    .scaledToFit()
                    
                    if !item.isFree {
                        HStack {
                            Image(.paidIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24)
                        }
                        .padding(.top, 3)
                        .padding(.leading, 7)
                    }
                    
                }
                .frame(width:112, height:112)
                .background(Color.white)
                .cornerRadius(10)

                // 아이템 이름
                Text(item.name)
                    .typography(.suit14SB18)
                    .foregroundColor(.black100)
            }
        }
        .buttonStyle(.plain)
    }

    /// 탭 핸들러 (키링은 바로 만들기, 나머지는 WorkshopPreview로 이동)
    private func handleTap() {
        guard let router = router else { return }

        // 키링일 경우 바로 해당 키링 Preview로 이동
        if let template = item as? KeyringTemplate,
           let templateId = template.id,
           let route = WorkshopRoute.from(string: templateId, showDeleteButton: showDeleteButton) {
            router.push(route)
        }
        // 나머지 아이템들은 WorkshopPreview로 이동
        else if let background = item as? Background {
            router.push(.workshopPreview(item: AnyHashable(background), showDeleteButton: showDeleteButton))
        } else if let carabiner = item as? Carabiner {
            router.push(.workshopPreview(item: AnyHashable(carabiner), showDeleteButton: showDeleteButton))
        } else if let particle = item as? Particle {
            router.push(.workshopPreview(item: AnyHashable(particle), showDeleteButton: showDeleteButton))
        } else if let sound = item as? Sound {
            router.push(.workshopPreview(item: AnyHashable(sound), showDeleteButton: showDeleteButton))
        }
    }
}

/// 공통 가격 오버레이 (유료 표시)
func priceOverlay<Item: WorkshopItem>(
    isFree: Bool,
    price: Int,
    isOwned: Bool,
    item: Item,
    effectManager: EffectManager,
    userManager: UserManager
) -> some View {
    VStack {
        HStack(spacing: 0) {
            if !isFree {
                HStack {
                    Image(.paidIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32)
                }
                .padding(.top, 7)
                .padding(.leading, 10)
            }

            Spacer()

            if isOwned {
                VStack {
                    Rectangle()
                        .fill(.black60)
                        .overlay(
                            Text("보유")
                                .typography(.suit13M)
                                .foregroundStyle(.white100)
                        )
                        .cornerRadius(20)
                        .frame(width: 43, height: 24)
                    
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
            }
        }
        .frame(width:175, height: 43)

        Spacer()

        // 사운드일 때만 재생 버튼 표시
        if item is Sound {
            HStack {
                Spacer()

                effectButtonStyle(
                    item: item,
                    effectManager: effectManager,
                    userManager: userManager
                )
            }
            .padding(8)
        }
    }
}

func effectButtonStyle<Item: WorkshopItem>(
    item: Item,
    effectManager: EffectManager,
    userManager: UserManager
) -> some View {
    let itemId = item.id ?? ""
    let isDownloading = effectManager.downloadingItemIds.contains(itemId)
    let progress = effectManager.downloadProgress[itemId] ?? 0.0

    return Button {
        Task {
            if let sound = item as? Sound {
                await effectManager.playSound(sound, userManager: userManager)
            }
        }
    } label: {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray50)
                .frame(width: 38, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white100, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)

            if isDownloading {
                // 다운로드 중이면 프로그레스 표시
                CircularProgressView(progress: progress)
                    .frame(width: 25, height: 25)
            } else {
                Image(.polygon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }
        }
    }
    .disabled(isDownloading)
}

/// 원형 프로그레스 뷰
struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray300, lineWidth: 2)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white100, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Action Buttons

/// 키링 템플릿 전용 액션 버튼
/// - 보유중이면 "만들기" 버튼 표시 (활성화)
/// - 유료이고 미보유면 구매 버튼 표시
/// - 무료이고 미보유면 "만들기" 버튼 표시 (활성화)
struct KeyringTemplateActionButton: View {
    let template: KeyringTemplate
    let isOwned: Bool
    let onMake: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        Group {
            if isOwned || template.isFree {
                // 보유중이거나 무료인 경우 만들기 버튼 (활성화)
                makeButton
            } else {
                // 유료이고 미보유인 경우 구매 버튼
                purchaseButton
            }
        }
    }

    /// 만들기 버튼 (활성화)
    private var makeButton: some View {
        Button {
            onMake()
        } label: {
            Text("만들기")
                .typography(.suit17B)
                .foregroundStyle(.white100)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.main500)
    }

    /// 구매 버튼 (유료)
    private var purchaseButton: some View {
        Button {
            onPurchase()
        } label: {
            HStack(spacing: 5) {
                Image(.buyKey)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32)

                Text("\(template.workshopPrice)")
                    .typography(.nanum18EB)
                    .foregroundStyle(.white100)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .buttonStyle(.glassProminent)
        .tint(.black80)
    }
}

/// WorkshopItem (배경, 카라비너, 이펙트 등) 전용 액션 버튼
/// - 무료면 "무료" 비활성화 버튼
/// - 보유중이면 "보유중" 비활성화 버튼
/// - 유료이고 미보유면 구매 버튼
struct WorkshopItemActionButton: View {
    let item: any WorkshopItem
    let isOwned: Bool
    let onPurchase: () -> Void

    var body: some View {
        Group {
            if item.isFree {
                disabledButton(text: "무료")
            } else if isOwned {
                disabledButton(text: "보유중")
            } else {
                purchaseButton
            }
        }
    }

    /// 비활성화 버튼 (무료 / 보유중)
    private func disabledButton(text: String) -> some View {
        Button {
            // 비활성화 - 아무 동작 없음
        } label: {
            Text(text)
                .typography(.suit17B)
                .foregroundStyle(.gray400)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.white100)
        .disabled(true)
    }

    /// 구매 버튼 (유료)
    private var purchaseButton: some View {
        Button {
            onPurchase()
        } label: {
            HStack(spacing: 5) {
                Image(.buyKey)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32)

                Text("\(item.workshopPrice)")
                    .typography(.nanum18EB)
                    .foregroundStyle(.white100)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
        }
        .buttonStyle(.glassProminent)
        .tint(.black80)
    }
}

// MARK: - Filter Bar

/// 워크샵 필터바 공통 컴포넌트
struct WorkshopFilterBar: View {
    @Binding var viewModel: WorkshopViewModel

    var body: some View {
        HStack(spacing: 8) {
            // 정렬 버튼 (고정)
            sortButton

            // 카테고리별 필터 (스크롤 가능)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categorySpecificFilters
                }
            }
        }
        .padding(.top, 12)
    }

    /// 정렬 버튼
    private var sortButton: some View {
        Button {
            viewModel.showFilterSheet = true
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.sortOrder)
                    .typography(.suit14SB18)
                    .foregroundColor(.gray500)

                Image(systemName: "chevron.down")
                    .foregroundColor(.gray500)
            }
            .padding(.horizontal, Spacing.gap)
            .padding(.vertical, Spacing.sm)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray50)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// 카테고리별 필터 옵션
    private var categorySpecificFilters: some View {
        Group {
            switch viewModel.selectedCategory {
            case "키링":
                ForEach(TemplateFilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedTemplateFilter == filter
                    ) {
                        viewModel.selectedTemplateFilter =
                            viewModel.selectedTemplateFilter == filter ? nil : filter
                    }
                }

            case "이펙트":
                ForEach(EffectFilterType.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedEffectFilter == filter
                    ) {
                        viewModel.selectedEffectFilter =
                            viewModel.selectedEffectFilter == filter ? nil : filter
                    }
                }

            case "카라비너":
                ForEach(viewModel.availableCarabinerTags, id: \.self) { tag in
                    FilterChip(
                        title: tag,
                        isSelected: viewModel.selectedCommonFilter == tag
                    ) {
                        viewModel.selectedCommonFilter =
                            viewModel.selectedCommonFilter == tag ? nil : tag
                    }
                }

            case "배경":
                ForEach(viewModel.availableBackgroundTags, id: \.self) { tag in
                    FilterChip(
                        title: tag,
                        isSelected: viewModel.selectedCommonFilter == tag
                    ) {
                        viewModel.selectedCommonFilter =
                            viewModel.selectedCommonFilter == tag ? nil : tag
                    }
                }

            default:
                EmptyView()
            }
        }
    }
}
