//
//  WorkshopGridHelpers.swift
//  Keychy
//
//  Created by Claude on 11/4/25.
//

import SwiftUI

/// 워크샵 그리드 레이아웃 헬퍼 함수들
struct WorkshopGridHelpers {

    /// 통합 아이템 그리드 뷰 (제네릭 타입)
    static func itemGridView<T: WorkshopItem>(
        items: [T],
        isOwnedCheck: @escaping (T) -> Bool,
        router: NavigationRouter<WorkshopRoute>?,
        viewModel: WorkshopViewModel?,
        emptyView: some View
    ) -> some View {
        gridLayout(isEmpty: items.isEmpty, emptyView: emptyView) {
            ForEach(items) { item in
                WorkshopItemView(
                    item: item,
                    isOwned: isOwnedCheck(item),
                    router: router,
                    viewModel: viewModel
                )
                .id(item.id)
            }
        }
    }

    /// 이펙트 그리드 뷰
    static func effectGridView(
        items: [any WorkshopItem],
        isSoundOwned: @escaping (Sound) -> Bool,
        isParticleOwned: @escaping (Particle) -> Bool,
        router: NavigationRouter<WorkshopRoute>?,
        viewModel: WorkshopViewModel?,
        emptyView: some View
    ) -> some View {
        gridLayout(isEmpty: items.isEmpty, emptyView: emptyView) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if let sound = item as? Sound {
                    WorkshopItemView(
                        item: sound,
                        isOwned: isSoundOwned(sound),
                        router: router,
                        viewModel: viewModel
                    )
                    .id(sound.id)
                } else if let particle = item as? Particle {
                    WorkshopItemView(
                        item: particle,
                        isOwned: isParticleOwned(particle),
                        router: router,
                        viewModel: viewModel
                    )
                    .id(particle.id)
                }
            }
        }
    }

    /// 공통 그리드 레이아웃
    private static func gridLayout<Content: View, EmptyView: View>(
        isEmpty: Bool,
        emptyView: EmptyView,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Group {
            if isEmpty {
                emptyView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 11) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 92)
            }
        }
    }
}
