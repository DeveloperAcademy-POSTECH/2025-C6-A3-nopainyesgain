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
            VStack {
                ZStack {
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
                                        .foregroundStyle(.gray300)                                
                                }
                        }
                    }
                    .scaledToFit()
                    .opacity(isParticlePlaying ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: isParticlePlaying)

                    // 파티클 Lottie 뷰를 같은 위치에 배치
                    if let particle = item as? Particle,
                       let particleId = particle.id,
                       effectManager.playingParticleId == particleId {
                        particleLottieView(particleId: particleId, effectManager: effectManager)
                    }
                }
            }
            .padding(.vertical,10)

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

    /// 현재 아이템의 파티클이 재생 중인지 확인
    private var isParticlePlaying: Bool {
        if let particle = item as? Particle,
           let particleId = particle.id {
            return effectManager.playingParticleId == particleId
        }
        return false
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

        // 현재 아이템 ID와 카테고리 저장
        viewModel?.savedScrollPosition = item.id
        viewModel?.savedCategory = viewModel?.selectedCategory

        // 키링일 경우 바로 해당 키링 Preview로 이동
        if let template = item as? KeyringTemplate,
           let templateId = template.id,
           let route = WorkshopRoute.from(string: templateId) {
            router.push(route)
        }
        // 나머지 아이템들은 WorkshopPreview로 이동
        else if let background = item as? Background {
            router.push(.workshopPreview(item: AnyHashable(background)))
        } else if let carabiner = item as? Carabiner {
            router.push(.workshopPreview(item: AnyHashable(carabiner)))
        } else if let particle = item as? Particle {
            router.push(.workshopPreview(item: AnyHashable(particle)))
        } else if let sound = item as? Sound {
            router.push(.workshopPreview(item: AnyHashable(sound)))
        }
    }
}

/// 보유한 아이템을 표시하는 작은 카드 뷰
struct OwnedItemCard<Item: WorkshopItem>: View {
    let item: Item
    var router: NavigationRouter<WorkshopRoute>? = nil
    var viewModel: WorkshopViewModel? = nil

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
                            Color.gray50
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

    /// 탭 핸들러 (키링은 바로 만들기, 나머지는 WorkshopPreview로 이동)
    private func handleTap() {
        guard let router = router else { return }

        // 카테고리만 저장
        viewModel?.savedCategory = viewModel?.selectedCategory

        // 키링일 경우 바로 해당 키링 Preview로 이동
        if let template = item as? KeyringTemplate,
           let templateId = template.id,
           let route = WorkshopRoute.from(string: templateId) {
            router.push(route)
        }
        // 나머지 아이템들은 WorkshopPreview로 이동
        else if let background = item as? Background {
            router.push(.workshopPreview(item: AnyHashable(background)))
        } else if let carabiner = item as? Carabiner {
            router.push(.workshopPreview(item: AnyHashable(carabiner)))
        } else if let particle = item as? Particle {
            router.push(.workshopPreview(item: AnyHashable(particle)))
        } else if let sound = item as? Sound {
            router.push(.workshopPreview(item: AnyHashable(sound)))
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
            if isOwned || !isFree {
                Image(.keyHole)
                    .padding(.leading, 10)
                    .padding(.top, 7)

                Spacer()

                if isOwned {
                    VStack {
                        Image(.owned)
                        
                        Spacer()
                    }
                }
            }
        }
        .frame(height: 43)

        Spacer()

        // 이펙트 타입일 때만 재생 버튼 표시
        if item is Sound || item is Particle {
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

/// 파티클 Lottie 뷰
func particleLottieView(particleId: String, effectManager: EffectManager) -> some View {
    LottieView(
        name: particleId,
        loopMode: .playOnce,
        speed: 1.0
    )
    .transition(.opacity)
    .animation(.easeInOut(duration: 0.3), value: effectManager.playingParticleId)
    .onAppear {
        // 애니메이션 시간만큼 대기 후 재생 상태 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                effectManager.playingParticleId = nil
            }
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
            } else if let particle = item as? Particle {
                await effectManager.playParticle(particle, userManager: userManager)
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
                    .frame(width: 20, height: 20)
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
                .stroke(.main500, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
    }
}
