//
//  WorkshopComponents.swift
//  Keychy
//
//  Created by rundo on 10/31/25.
//

import SwiftUI
import NukeUI

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
            VStack {
                LazyImage(url: URL(string: item.thumbnailURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if state.isLoading {
                        Color.gray50
                            .overlay { ProgressView() }
                    } else {
                        Color.gray50
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.gray50)
                            }
                    }
                }
                .scaledToFit()
            }
            .padding(.vertical,10)

            // 가격 오버레이
            priceOverlay(
                isFree: item.isFree,
                price: item.workshopPrice,
                isOwned: isOwned
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

    /// 탭 핸들러 (KeyringTemplate만 네비게이션)
    private func handleTap() {
        if let template = item as? KeyringTemplate,
           let router = router,
           let route = WorkshopRoute.from(string: template.id!) {
            router.push(route)
        }
    }
}

/// 보유한 아이템을 표시하는 작은 카드 뷰
struct OwnedItemCard<Item: WorkshopItem>: View {
    let item: Item
    var router: NavigationRouter<WorkshopRoute>? = nil

    var body: some View {
        Button {
            handleTap()
        } label: {
            VStack(spacing: 8) {
                VStack {
                    LazyImage(url: URL(string: item.thumbnailURL)) { state in
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
                    .scaledToFit()
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

    /// 탭 핸들러 (KeyringTemplate만 네비게이션)
    private func handleTap() {
        if let template = item as? KeyringTemplate,
           let router = router,
           let route = WorkshopRoute.from(string: template.id!) {
            router.push(route)
        }
    }
}

/// 공통 가격 오버레이 (유료 표시)
func priceOverlay(isFree: Bool, price: Int, isOwned: Bool) -> some View {
    VStack {
        HStack(spacing: 0) {
            if isOwned || !isFree {
                Image(.keyHole)
                    .padding(.leading, 10)
                    .padding(.top, 7)

                Spacer()

                if isOwned {
                    Image(.owned)
                }
            }
        }
        .frame(height: 43)
        
        Spacer()
    }
}
