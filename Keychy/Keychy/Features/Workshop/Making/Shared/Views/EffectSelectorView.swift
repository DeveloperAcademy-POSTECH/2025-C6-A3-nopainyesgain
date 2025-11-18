//
//  EffectSelectorView.swift
//  Keychy
//
//  Effect 모드 하단 콘텐츠 뷰 (사운드 + 파티클 선택)
//  - 모든 템플릿에서 공통으로 사용
//

import SwiftUI

struct EffectSelectorView<VM: KeyringViewModelProtocol>: View {
    @Bindable var viewModel: VM
    @Binding var cartItems: [EffectItem]

    @State private var showRecordingSheet = false

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 24) {
                // 탭 사운드 섹션
                soundEffectSelector

                // 흔들기 효과 섹션
                particleEffectSelector
                Spacer()
            }
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
            .fill(.white100)
            .shadow(color: .black.opacity(0.15), radius: 9)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Sound Effect Selector

    /// 사운드 이펙트 선택 버튼 그룹
    private var soundEffectSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("탭 사운드")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
                .padding(.top, 30)

            HStack(spacing: 0) {
                // 녹음 버튼
                Button {
                    showRecordingSheet = true
                } label: {
                    Image("record")
                        .frame(width: 32, height: 32)
                }
                .padding(.leading, 20)
                .padding(.trailing, 8)
                .sheet(isPresented: $showRecordingSheet) {
                    RecordingSheet { url in
                        viewModel.applyCustomSound(url)
                    }
                }

                // 버튼들만 스크롤
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // "없음" 버튼
                            Button {
                                viewModel.updateSound(nil)
                            } label: {
                                Text("없음")
                                    .typography(viewModel.selectedSound == nil && !viewModel.hasCustomSound ? .suit15SB25 : .suit15M25)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .foregroundStyle(viewModel.selectedSound == nil && !viewModel.hasCustomSound ? .white100 : .gray500)
                                    .background(viewModel.selectedSound == nil && !viewModel.hasCustomSound ? .main500 : .gray50)
                                    .clipShape(.rect(cornerRadius: 15))
                            }
                            .id("sound_none")

                            // "음성 메모" 버튼 (커스텀 사운드가 있을 때만)
                            if viewModel.hasCustomSound {
                                Button {
                                    viewModel.applyCustomSound(viewModel.customSoundURL!)
                                } label: {
                                    Text("음성 메모")
                                        .typography(viewModel.soundId == "custom_recording" ? .suit15SB25 : .suit15M25)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 9)
                                        .foregroundStyle(viewModel.soundId == "custom_recording" ? .white100 : .gray500)
                                        .background(viewModel.soundId == "custom_recording" ? .main500 : .gray50)
                                        .clipShape(.rect(cornerRadius: 15))
                                }
                                .id("sound_custom")
                            }

                            // Firebase 사운드 목록 (정렬됨)
                            ForEach(viewModel.sortedAvailableSounds) { sound in
                                soundItemButton(sound: sound)
                                    .id(sound.id)
                            }
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 20)
                    }
                    .onChange(of: viewModel.selectedSound?.id) { _, newValue in
                        if let soundId = newValue {
                            withAnimation {
                                proxy.scrollTo(soundId, anchor: .center)
                            }
                        }
                    }
                }
                .overlay(alignment: .leading) {
                    // Rectangle을 위에 겹쳐서 자연스럽게 가림
                    Rectangle()
                        .fill(.gray50)
                        .frame(width: 3, height: 40)
                        .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Particle Effect Selector

    /// 파티클 이펙트 선택 버튼 그룹
    private var particleEffectSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("흔들기 효과")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "없음" 버튼
                        Button {
                            viewModel.updateParticle(nil)
                        } label: {
                            Text("없음")
                                .typography(viewModel.selectedParticle == nil ? .suit15SB25 : .suit15M25)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .foregroundStyle(viewModel.selectedParticle == nil ? .white100 : .gray500)
                                .background(viewModel.selectedParticle == nil ? .main500 : .gray50)
                                .clipShape(.rect(cornerRadius: 15))
                        }
                        .id("particle_none")

                        // Firebase 파티클 목록 (정렬됨)
                        ForEach(viewModel.sortedAvailableParticles) { particle in
                            particleItemButton(particle: particle)
                                .id(particle.id)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onChange(of: viewModel.selectedParticle?.id) { _, newValue in
                    if let particleId = newValue {
                        withAnimation {
                            proxy.scrollTo(particleId, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Item Button Helpers

    /// 사운드 아이템 버튼
    @ViewBuilder
    private func soundItemButton(sound: Sound) -> some View {
        if let soundId = sound.id {
            let isInBundle = viewModel.isInBundle(soundId: soundId)
            let isInCache = viewModel.isInCache(soundId: soundId)
            let isOwned = viewModel.isOwned(soundId: soundId)
            let isDownloading = viewModel.downloadingItemIds.contains(soundId)
            let isSelected = viewModel.selectedSound?.id == soundId

            // UI 스타일 계산
            let isPaidUnownedUnselected = !sound.isFree && !isOwned && !isSelected
            let isPaidOwnedSelected = !sound.isFree && isOwned && isSelected
            let isPaidUnOwnedSelected = !sound.isFree && !isOwned && isSelected

            Button {
                // 이미 선택된 상태라면 선택 해제
                if isSelected {
                    viewModel.updateSound(nil)
                    // 장바구니에 있다면 제거
                    if !isOwned && !sound.isFree {
                        removeFromCart(sound.id ?? "")
                    }
                }
                // 선택되지 않은 상태라면 선택
                else {
                    // 케이스 1: Bundle 무료 → 바로 사용
                    if isInBundle {
                        viewModel.updateSound(sound)
                        // 장바구니에서 사운드 타입 제거 (무료로 교체)
                        cartItems.removeAll { $0.type == .sound }
                    }
                    // 케이스 2: 구매 + 캐시 있음 → 바로 사용
                    else if isOwned && isInCache {
                        viewModel.updateSound(sound)
                        // 장바구니에서 사운드 타입 제거 (보유템으로 교체)
                        cartItems.removeAll { $0.type == .sound }
                    }
                    // 케이스 3: 구매 + 캐시 없음 → 재다운로드
                    else if isOwned && !isInCache {
                        Task {
                            await viewModel.downloadSound(sound)
                        }
                        // 장바구니에서 사운드 타입 제거 (보유템으로 교체)
                        cartItems.removeAll { $0.type == .sound }
                    }
                    // 케이스 4: 미구매 + 무료 + 캐시 있음 → 바로 사용
                    else if !isOwned && sound.isFree && isInCache {
                        viewModel.updateSound(sound)
                        // 장바구니에서 사운드 타입 제거 (무료로 교체)
                        cartItems.removeAll { $0.type == .sound }
                    }
                    // 케이스 5: 미구매 + 무료 + 캐시 없음 → 다운로드
                    else if !isOwned && sound.isFree && !isInCache {
                        Task {
                            await viewModel.downloadSound(sound)
                        }
                        // 장바구니에서 사운드 타입 제거 (무료로 교체)
                        cartItems.removeAll { $0.type == .sound }
                    }
                    // 케이스 6: 미구매 + 유료 + 캐시 있음 → 다운로드 + 장바구니 추가
                    else if !isOwned && !sound.isFree && isInCache {
                        viewModel.updateSound(sound)
                        addSoundToCart(sound)
                    }
                    // 케이스 7: 미구매 + 유료 + 캐시 없음 → 다운로드 + 장바구니 추가
                    else {
                        Task {
                            await viewModel.downloadSound(sound)
                        }
                        addSoundToCart(sound)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    // 유료 아이콘
                    if !sound.isFree {
                        if isOwned {
                            // 유료 + 보유
                            if isSelected {
                                Image("whiteEffectSelect")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image("grayEffectSelect")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            }
                        } else {
                            // 유료 + 미보유
                            if isSelected {
                                Image("whiteEffectSelect")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image("gradientEffectSelect")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            }
                        }
                    }

                    Text(sound.soundName)
                        .typography(isSelected ? .suit15SB25 : .suit15M25)

                    // 다운로드 안됨: download 아이콘
                    if !isInCache && !isInBundle {
                        Image("download")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Group {
                        if isPaidOwnedSelected {
                            // 유료 + 보유 + 선택 → 백그라운드 gradient
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.main500)
                        } else if isPaidUnOwnedSelected {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.gradient(.primary))
                        }
                        else if isSelected {
                            // 나머지 선택 → 백그라운드 .main500
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.main500)
                        } else {
                            // 미선택 → 백그라운드 .gray50
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.gray50)
                        }
                    }
                )
                .foregroundStyle(
                    isPaidUnownedUnselected ?
                    AnyShapeStyle(.gradient(.primary)) :
                        isSelected ?
                    AnyShapeStyle(.white100) :
                        AnyShapeStyle(.gray500)
                )
                .overlay(
                    // 다운로드 중 프로그레스
                    Group {
                        if isDownloading {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.black.opacity(0.3))

                                if let progress = viewModel.downloadProgress[soundId], progress.isFinite {
                                    VStack(spacing: 0) {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.7)
                                        Text("\(Int(min(max(progress * 100, 0), 100)))%")
                                            .typography(.nanum14EB18)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                    }
                )
            }
            .disabled(isDownloading)
        }
    }

    /// 파티클 아이템 버튼
    @ViewBuilder
    private func particleItemButton(particle: Particle) -> some View {
        if let particleId = particle.id {
            let isInBundle = viewModel.isInBundle(particleId: particleId)
            let isInCache = viewModel.isInCache(particleId: particleId)
            let isOwned = viewModel.isOwned(particleId: particleId)
            let isDownloading = viewModel.downloadingItemIds.contains(particleId)
            let isSelected = viewModel.selectedParticle?.id == particleId

            // UI 스타일 계산
            let isPaidUnownedUnselected = !particle.isFree && !isOwned && !isSelected
            let isPaidOwnedSelected = !particle.isFree && isOwned && isSelected
            let isPaidUnOwnedSelected = !particle.isFree && !isOwned && isSelected

            Button {
                // 이미 선택된 상태라면 선택 해제
                if isSelected {
                    viewModel.updateParticle(nil)
                    // 장바구니에 있다면 제거
                    if !isOwned && !particle.isFree {
                        removeFromCart(particle.id ?? "")
                    }
                }
                // 선택되지 않은 상태라면 선택
                else {
                    // 케이스 1: Bundle 무료 → 바로 사용
                    if isInBundle {
                        viewModel.updateParticle(particle)
                        // 장바구니에서 파티클 타입 제거 (무료로 교체)
                        cartItems.removeAll { $0.type == .particle }
                    }
                    // 케이스 2: 구매 + 캐시 있음 → 바로 사용
                    else if isOwned && isInCache {
                        viewModel.updateParticle(particle)
                        // 장바구니에서 파티클 타입 제거 (보유템으로 교체)
                        cartItems.removeAll { $0.type == .particle }
                    }
                    // 케이스 3: 구매 + 캐시 없음 → 재다운로드
                    else if isOwned && !isInCache {
                        Task {
                            await viewModel.downloadParticle(particle)
                        }
                        // 장바구니에서 파티클 타입 제거 (보유템으로 교체)
                        cartItems.removeAll { $0.type == .particle }
                    }
                    // 케이스 4: 미구매 + 무료 + 캐시 있음 → 바로 사용
                    else if !isOwned && particle.isFree && isInCache {
                        viewModel.updateParticle(particle)
                        // 장바구니에서 파티클 타입 제거 (무료로 교체)
                        cartItems.removeAll { $0.type == .particle }
                    }
                    // 케이스 5: 미구매 + 무료 + 캐시 없음 → 다운로드
                    else if !isOwned && particle.isFree && !isInCache {
                        Task {
                            await viewModel.downloadParticle(particle)
                        }
                        // 장바구니에서 파티클 타입 제거 (무료로 교체)
                        cartItems.removeAll { $0.type == .particle }
                    }
                    // 케이스 6: 미구매 + 유료 + 캐시 있음 → 다운로드 + 장바구니 추가
                    else if !isOwned && !particle.isFree && isInCache {
                        viewModel.updateParticle(particle)
                        addParticleToCart(particle)
                    }
                    // 케이스 7: 미구매 + 유료 + 캐시 없음 → 다운로드 + 장바구니 추가
                    else {
                        Task {
                            await viewModel.downloadParticle(particle)
                        }
                        addParticleToCart(particle)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    // 유료 아이콘
                    if !particle.isFree {
                        if isOwned {
                            // 유료 + 보유
                            if isSelected {
                                Image("whiteEffectSelect")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image("grayEffectSelect")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            }
                        } else {
                            // 유료 + 미보유
                            if isSelected {
                                Image("whiteEffectSelect")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image("gradientEffectSelect")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            }
                        }
                    }

                    Text(particle.particleName)
                        .typography(isSelected ? .suit15SB25 : .suit15M25)

                    // 다운로드 안됨: download 아이콘
                    if !isInCache && !isInBundle {
                        Image("download")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Group {
                        if isPaidOwnedSelected {
                            // 유료 + 보유 + 선택 → 백그라운드 gradient
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.main500)
                        } else if isPaidUnOwnedSelected {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.gradient(.primary))
                        }
                        else if isSelected {
                            // 나머지 선택 → 백그라운드 .main500
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.main500)
                        } else {
                            // 미선택 → 백그라운드 .gray50
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.gray50)
                        }
                    }
                )
                .foregroundStyle(
                    isPaidUnownedUnselected ?
                    AnyShapeStyle(.gradient(.primary)) :

                        isSelected ?
                    AnyShapeStyle(.white100) :
                        AnyShapeStyle(.gray500)
                )
                .overlay(
                    // 다운로드 중 프로그레스
                    Group {
                        if isDownloading {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.black.opacity(0.3))

                                if let progress = viewModel.downloadProgress[particleId], progress.isFinite {
                                    VStack(spacing: 2) {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.7)
                                        Text("\(Int(min(max(progress * 100, 0), 100)))%")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                    }
                )
            }
            .disabled(isDownloading)
        }
    }

    // MARK: - Cart Helpers

    /// 사운드를 장바구니에 추가 (사운드는 1개만 담을 수 있음)
    private func addSoundToCart(_ sound: Sound) {
        // 기존 사운드가 있다면 제거
        cartItems.removeAll { $0.type == .sound }

        // 새 사운드 추가
        let item = EffectItem(sound: sound)
        cartItems.append(item)
    }

    /// 파티클을 장바구니에 추가 (파티클은 1개만 담을 수 있음)
    private func addParticleToCart(_ particle: Particle) {
        // 기존 파티클이 있다면 제거
        cartItems.removeAll { $0.type == .particle }

        // 새 파티클 추가
        let item = EffectItem(particle: particle)
        cartItems.append(item)
    }

    /// 장바구니에서 아이템 제거
    private func removeFromCart(_ itemId: String) {
        cartItems.removeAll { $0.id == itemId }
    }
}
