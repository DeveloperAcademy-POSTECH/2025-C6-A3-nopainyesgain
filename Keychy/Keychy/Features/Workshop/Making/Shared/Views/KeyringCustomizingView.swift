//
//  KeyringCustomizingView.swift
//  KeytschPrototype
//
//  Generic 키링 커스터마이징 화면
//  - 모든 템플릿에서 공통으로 사용 가능
//  - KeyringSceneView도 Generic이므로 주입 불필요
//

import SwiftUI
import SpriteKit
import Lottie

struct KeyringCustomizingView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: VM
    let navigationTitle: String
    let nextRoute: WorkshopRoute
    
    @State private var selectedMode: CustomizingMode = .effect
    @State private var isLoadingResources = true
    @State private var isSceneReady = false
    @State private var loadingScale: CGFloat = 0.3
    @State private var showRecordingSheet = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack(alignment: .center) {
                    KeyringSceneView(viewModel: viewModel, onSceneReady: {
                        withAnimation(.easeIn(duration: 0.3)) {
                            isSceneReady = true
                        }
                        closeLoadingIfReady()
                    })
                    // 준비되면 fade-in하게 했음.
                    .opacity(isSceneReady ? 1.0 : 0.0)

                    // 로딩 인디케이터 (키링씬 중앙)
                    if isLoadingResources || !isSceneReady {
                        loadingIndicator()
                    }
                    
                    // 모드 선택 버튼들 (템플릿마다 다른 선택지 제공, 뷰모델에 명시!)
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(viewModel.availableCustomizingModes) { mode in
                            modeButton(for: mode)
                        }
                        Spacer()
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }

                // MARK: - 하단 영역
                bottomContentView
            }
            .background(.gray50)
            .disabled(isLoadingResources || !isSceneReady)
        }
        .navigationTitle(navigationTitle)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
        .task {
            // Firebase에서 이펙트 데이터 가져오기
            await viewModel.fetchEffects()

            // 사운드 + 파티클 병렬 프리로딩
            async let soundsTask: () = preloadAllSoundEffects()
            async let particlesTask: () = preloadAllParticleEffects()

            await soundsTask
            await particlesTask

            // 리소스 프리로딩 완료
            isLoadingResources = false
            closeLoadingIfReady()
        }
    }

    // MARK: - Loading Helper
    private func closeLoadingIfReady() {
        // 리소스 + 씬 모두 준비되면 로딩 닫기
        if !isLoadingResources && isSceneReady {
            withAnimation {
                // 이미 조건이 맞으면 자동으로 UI 업데이트됨
            }
        }
    }

    // MARK: - Preload Sound Resources
    private func preloadAllSoundEffects() async {
        // Firebase에서 가져온 사운드를 순차적으로 로드
        for sound in viewModel.availableSounds {
            guard let soundId = sound.id else { continue }
            await SoundEffectComponent.shared.preloadSound(named: soundId)
        }
    }

    // MARK: - Preload Particle Resources
    private func preloadAllParticleEffects() async {
        // Firebase에서 가져온 파티클을 순차적으로 로드
        for particle in viewModel.availableParticles {
            guard let particleId = particle.id else { continue }
            await preloadParticle(named: particleId)
        }
    }

    private func preloadParticle(named particleId: String) async {
        // 백그라운드 스레드에서 파일 로딩 (UI 블로킹 방지)
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

                // 캐시에서 로드 시도
                if FileManager.default.fileExists(atPath: cachedURL.path) {
                    _ = LottieAnimation.filepath(cachedURL.path)
                }
                // Bundle에서 로드 시도
                else {
                    _ = LottieAnimation.named(particleId)
                }

                continuation.resume()
            }
        }
    }
}

// MARK: - Toolbar Section
extension KeyringCustomizingView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }
    private var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("다음") {
                router.push(nextRoute)
            }
        }
    }
}

// MARK: - Mode Selection & Bottom Content Section
extension KeyringCustomizingView {
    /// 로딩 인디케이터
    private func loadingIndicator() -> some View {
        VStack(spacing: 23) {
            Image("appIcon")

            Text("키링을 만들고 있어요")
                .typography(.suit17SB)
        }
        .padding(20)
        .scaleEffect(loadingScale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                loadingScale = 1.0
            }
        }
    }
    
    /// 모드 선택 버튼
    private func modeButton(for mode: CustomizingMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(selectedMode == mode ? .main500 : .white100)
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.25), radius: 4)
                
                Image(mode.btnImage)
                    .foregroundStyle(selectedMode == mode ? .white100 : .gray400)
                
            }
        }
        .scaleEffect(selectedMode == mode ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedMode)
    }
    
    /// 선택된 모드에 따라 하단 영역 변경
    @ViewBuilder
    private var bottomContentView: some View {
        switch selectedMode {
        case .effect:
            effectSelectorView
            // 나중에 추가: case .drawing: drawingView
        }
    }
    
    /// 효과 선택 화면 (사운드 + 파티클 통합)
    private var effectSelectorView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 탭 사운드 섹션
            soundEffectSelector
            
            // 흔들기 효과 섹션
            particleEffectSelector
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 310, alignment: .topLeading)
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
                        }

                        // Firebase 사운드 목록
                        ForEach(viewModel.availableSounds) { sound in
                            soundItemButton(sound: sound)
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 20)
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
    
    /// 파티클 이펙트 선택 버튼 그룹
    private var particleEffectSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("흔들기 효과")
                .typography(.suit16B)
                .foregroundStyle(.black100)
                .padding(.leading, 20)
            
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
                    
                    // Firebase 파티클 목록
                    ForEach(viewModel.availableParticles) { particle in
                        particleItemButton(particle: particle)
                    }
                }
                .padding(.horizontal, 20)
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
                // 케이스 1: Bundle 무료 → 바로 사용
                if isInBundle {
                    viewModel.updateSound(sound)
                }
                // 케이스 2: 구매 + 캐시 있음 → 바로 사용
                else if isOwned && isInCache {
                    viewModel.updateSound(sound)
                }
                // 케이스 3: 구매 + 캐시 없음 → 재다운로드
                else if isOwned && !isInCache {
                    Task {
                        await viewModel.downloadSound(sound)
                    }
                }
                // 케이스 4: 미구매 + 무료 + 캐시 있음 → 바로 사용
                else if !isOwned && sound.isFree && isInCache {
                    viewModel.updateSound(sound)
                }
                // 케이스 5: 미구매 + 무료 + 캐시 없음 → 다운로드
                else if !isOwned && sound.isFree && !isInCache {
                    Task {
                        await viewModel.downloadSound(sound)
                    }
                }
                // 케이스 6: 미구매 + 유료 + 캐시 있음 → 바로 사용 (체험)
                else if !isOwned && !sound.isFree && isInCache {
                    // TODO: 저장 시점에 구매 체크 및 구매 플로우 필요
                    viewModel.updateSound(sound)
                }
                // 케이스 7: 미구매 + 유료 + 캐시 없음 → 다운로드 (체험)
                else {
                    // TODO: 저장 시점에 구매 체크 및 구매 플로우 필요
                    Task {
                        await viewModel.downloadSound(sound)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    // 유료 아이콘
                    if !sound.isFree {
                        if isOwned {
                            // 유료 + 보유
                            Image("ownPaid")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                        } else {
                            // 유료 + 미보유
                            if isSelected {
                                Image("selectPaid")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image("deselectPaid")
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
                                .fill(.gradient(.primary))
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
                // 케이스 1: Bundle 무료 → 바로 사용
                if isInBundle {
                    viewModel.updateParticle(particle)
                }
                // 케이스 2: 구매 + 캐시 있음 → 바로 사용
                else if isOwned && isInCache {
                    viewModel.updateParticle(particle)
                }
                // 케이스 3: 구매 + 캐시 없음 → 재다운로드
                else if isOwned && !isInCache {
                    Task {
                        await viewModel.downloadParticle(particle)
                    }
                }
                // 케이스 4: 미구매 + 무료 + 캐시 있음 → 바로 사용
                else if !isOwned && particle.isFree && isInCache {
                    viewModel.updateParticle(particle)
                }
                // 케이스 5: 미구매 + 무료 + 캐시 없음 → 다운로드
                else if !isOwned && particle.isFree && !isInCache {
                    Task {
                        await viewModel.downloadParticle(particle)
                    }
                }
                // 케이스 6: 미구매 + 유료 + 캐시 있음 → 바로 사용 (체험)
                else if !isOwned && !particle.isFree && isInCache {
                    // TODO: 저장 시점에 구매 체크 및 구매 플로우 필요
                    viewModel.updateParticle(particle)
                }
                // 케이스 7: 미구매 + 유료 + 캐시 없음 → 다운로드 (체험)
                else {
                    // TODO: 저장 시점에 구매 체크 및 구매 플로우 필요
                    Task {
                        await viewModel.downloadParticle(particle)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    // 유료 아이콘
                    if !particle.isFree {
                        if isOwned {
                            // 유료 + 보유
                            Image("ownPaid")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                        } else {
                            // 유료 + 미보유
                            if isSelected {
                                Image("selectPaid")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image("deselectPaid")
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
                                .fill(.gradient(.primary))
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
}
