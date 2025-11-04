//
//  WorkshopMainContentSection.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - Main Content Section

extension WorkshopView {
    /// 메인 콘텐츠 영역 (카테고리별 그리드)
    var mainContentSection: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else {
                if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    categoryContent
                }
            }
        }
        .background(.white100)
    }

    /// 로딩 뷰
    var loadingView: some View {
        HStack(spacing: 0) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }


    /// 카테고리별 콘텐츠
    var categoryContent: some View {
        Group {
            switch viewModel.selectedCategory {
            case "KEYCHY!":
                keychyContentView
            case "키링":
                itemGridView(items: viewModel.filteredTemplates,
                           isOwnedCheck: viewModel.isTemplateOwned)
            case "배경":
                itemGridView(items: viewModel.filteredBackgrounds,
                           isOwnedCheck: viewModel.isBackgroundOwned)
            case "카라비너":
                itemGridView(items: viewModel.filteredCarabiners,
                           isOwnedCheck: viewModel.isCarabinerOwned)
            case "이펙트":
                effectContentView
            default:
                emptyContentView
            }
        }
    }

    /// 이펙트 전용 콘텐츠 (사운드 + 파티클)
    var effectContentView: some View {
        Group {
            let items = viewModel.filteredEffects

            if items.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 11) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        if let sound = item as? Sound {
                            WorkshopItemView(
                                item: sound,
                                isOwned: viewModel.isSoundOwned(sound),
                                router: router,
                                viewModel: viewModel
                            )
                            .id(sound.id)
                        } else if let particle = item as? Particle {
                            WorkshopItemView(
                                item: particle,
                                isOwned: viewModel.isParticleOwned(particle),
                                router: router,
                                viewModel: viewModel
                            )
                            .id(particle.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 92)
            }
        }
    }

    /// 통합 아이템 그리드 뷰
    func itemGridView<T: WorkshopItem>(
        items: [T],
        isOwnedCheck: @escaping (T) -> Bool
    ) -> some View {
        Group {
            if items.isEmpty {
                emptyContentView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 11) {
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
                .padding(.horizontal, 16)
                .padding(.top, 92)
            }
        }
    }

    /// KEYCHY! 전용 콘텐츠 (준비 중)
    var keychyContentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.purple).opacity(0.6)

            Text("KEYCHY! 디자이너 열일중..")
                .typography(.suit14SB18)
                .foregroundColor(.gray500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }

    /// 빈 콘텐츠 뷰
    var emptyContentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.purple).opacity(0.6)

            Text("Comming Soon~")
                .typography(.suit14SB18)
                .foregroundColor(.gray500)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.top, 50)
    }

    /// 에러 뷰
    func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                Task {
                    await viewModel.fetchAllData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 100)
    }
}
