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
    let nextRoute: WorkshopRoute

    @State private var selectedMode: CustomizingMode = .effect  // onAppear에서 첫 번째 모드로 재설정됨
    @State private var isLoadingResources = true
    @State private var isSceneReady = false
    @State private var loadingScale: CGFloat = 0.3
    @State private var showResetAlert = false
    @State private var isInitialBottomViewAppear = true  // 첫 진입 여부 추적
    @State private var bottomViewOpacity: Double = 0  // 하단 영역 opacity
    @State private var bottomViewOffset: CGFloat = 30  // 하단 영역 offset
    @State private var currentBottomViewHeightRatio: CGFloat = 0.35  // 현재 하단 뷰 높이 비율

    // 구매 시트
    @State var showPurchaseSheet = false
    @State var cartItems: [EffectItem] = []

    // 구매 시트 높이 계산 (기본 301 + 각 아이템 row당 60씩 증가)
    var purchaseSheetHeight: CGFloat {
        let baseHeight: CGFloat = 301
        let rowHeight: CGFloat = 60
        return baseHeight + (CGFloat(max(0, cartItems.count - 1)) * rowHeight)
    }

    // 구매 Alert 애니메이션
    @State var showPurchaseProgress = false
    @State var showPurchaseSuccessAlert = false
    @State var purchaseSuccessScale: CGFloat = 0.3
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 모드별 씬 뷰 (ViewModel에서 제공) - 전체 화면 고정
                currentSceneView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray50.ignoresSafeArea())
                    .offset(y: -60)
                    .opacity(isSceneReady ? 1.0 : 0.0)

                // 모드 선택 버튼들 (템플릿마다 다른 선택지 제공, 뷰모델에 명시!)
                VStack(spacing: 0) {
                    Spacer()

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(viewModel.availableCustomizingModes) { mode in
                            modeButton(for: mode)
                        }
                        Spacer()
                    }
                    .cinematicAppear(delay: 0.3, duration: 1.0, style: .slideUp)
                    .padding(18)
                    .padding(.bottom, geometry.size.height * currentBottomViewHeightRatio)
                }

                // MARK: - 하단 영역 (모드별로 다른 콘텐츠) - bottom 고정
                VStack(spacing: 0) {
                    Spacer()

                    currentBottomView
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: geometry.size.height * currentBottomViewHeightRatio,
                            alignment: .top)
                }
            }
            .blur(radius: showPurchaseProgress || showPurchaseSuccessAlert || showPurchaseFailAlert || showResetAlert || isLoadingResources || !isSceneReady ? 15 : 0)
            .disabled(isLoadingResources || !isSceneReady)

            // MARK: - 딤 처리 (코인 부족 Alert 표시 시)
            if showPurchaseFailAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .zIndex(1)
            }

            // MARK: - 구매 중 로딩
            if showPurchaseProgress {
                LoadingAlert(type: .short, message: nil)
            }

            // MARK: - Purchase Alerts
            if showPurchaseSuccessAlert {
                PurchaseSuccessAlert(checkmarkScale: purchaseSuccessScale)
                    .padding(.bottom, 60)
                    .padding(.horizontal, 51)
            }

            if showPurchaseFailAlert {
                PurchaseFailAlert(
                    checkmarkScale: purchaseFailScale,
                    onCancel: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            purchaseFailScale = 0.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showPurchaseFailAlert = false
                            // Alert 닫힌 후 시트 다시 열기
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showPurchaseSheet = true
                            }
                        }
                    },
                    onCharge: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            purchaseFailScale = 0.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showPurchaseFailAlert = false
                            // 충전 페이지로 이동
                            router.push(.coinCharge)
                        }
                    }
                )
                .padding(.horizontal, 51)
                .zIndex(2)
            }

            // MARK: - 커스텀 네비게이션 바
            customNavigationBar
                .blur(radius: showPurchaseProgress || showPurchaseSuccessAlert || isLoadingResources || !isSceneReady ? 15 : 0)
                .opacity(showPurchaseProgress || showPurchaseSuccessAlert ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: showPurchaseProgress)
                .animation(.easeInOut(duration: 0.2), value: showPurchaseSuccessAlert)
                .zIndex(0)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .swipeBackGesture(enabled: false)
        .interactiveDismissDisabled(true)
        .alert("작업을 취소하시겠습니까?", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) { }
            Button("확인", role: .destructive) {
                viewModel.resetAll()
                router.reset()
            }
        } message: {
            Text("지금까지 작업한 내용이 모두 초기화됩니다.")
        }
        .task {
            // 첫 번째 모드를 기본 선택
            if let firstMode = viewModel.availableCustomizingModes.first {
                selectedMode = firstMode
                currentBottomViewHeightRatio = viewModel.bottomViewHeightRatio(for: firstMode)
            }

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
        .sheet(isPresented: $showPurchaseSheet) {
            purchaseSheet
        }
        .onChange(of: selectedMode) { oldMode, newMode in
            // 첫 진입 이후 모드 전환 시 애니메이션 비활성화
            isInitialBottomViewAppear = false

            // 높이 비율 변경 (스프링 없이 부드러운 애니메이션)
            withAnimation(.easeInOut(duration: 0.4)) {
                currentBottomViewHeightRatio = viewModel.bottomViewHeightRatio(for: newMode)
            }

            // 모드 변경 시 템플릿별 처리
            viewModel.onModeChanged(from: oldMode, to: newMode)
        }
    }

    // MARK: - Loading Helper
    private func closeLoadingIfReady() {
        // 리소스 + 씬 모두 준비되면 로딩 닫기
        if !isLoadingResources && isSceneReady {
            // 사라지는 애니메이션
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                loadingScale = 0.3
            }
        }
    }

    // MARK: - Preload Sound Resources
    private func preloadAllSoundEffects() async {
        // Firebase에서 가져온 사운드를 병렬로 로드
        await withTaskGroup(of: Void.self) { group in
            for sound in viewModel.availableSounds {
                guard let soundId = sound.id else { continue }
                group.addTask {
                    await SoundEffectComponent.shared.preloadSound(named: soundId)
                }
            }
        }
    }

    // MARK: - Preload Particle Resources
    private func preloadAllParticleEffects() async {
        // 보유한 파티클만 병렬로 로드 (미보유는 스킵)
        await withTaskGroup(of: Void.self) { group in
            for particle in viewModel.availableParticles {
                guard let particleId = particle.id else { continue }

                // 보유 여부 미리 확인
                let isOwned = viewModel.isOwned(particleId: particleId)
                let isFree = particle.isFree

                // 보유하거나 무료인 것만 로드
                if isOwned || isFree {
                    group.addTask {
                        await self.preloadParticle(named: particleId)
                    }
                }
            }
        }
    }

    private func preloadParticle(named particleId: String) async {
        // 백그라운드 스레드에서 파일 로딩 (UI 블로킹 방지)
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

                // 1. 캐시에 있으면 로드 (보유 유료 파티클)
                if FileManager.default.fileExists(atPath: cachedURL.path) {
                    _ = LottieAnimation.filepath(cachedURL.path)
                    continuation.resume()
                    return
                }

                // 2. Bundle에 있는지 확인 후 로드 (무료 파티클)
                if Bundle.main.path(forResource: particleId, ofType: "json") != nil {
                    _ = LottieAnimation.named(particleId)
                    continuation.resume()
                    return
                }

                // 3. 둘 다 없으면 조용히 스킵 (미보유 유료 파티클)
                continuation.resume()
            }
        }
    }
}

// MARK: - Custom Navigation Bar
extension KeyringCustomizingView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽) - 뒤로가기 버튼
            BackToolbarButton {
                showResetAlert = true
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        } center: {
            // Center (중앙) - 빈 공간
            Spacer()
        } trailing: {
            // Trailing (오른쪽) - 다음/구매 버튼
            Button {
                if hasCartItems {
                    showPurchaseSheet = true
                } else {
                    // 다음으로 넘어가기 전 템플릿별 처리
                    viewModel.beforeNavigateToNext()
                    router.push(nextRoute)
                }
            } label: {
                Text(hasCartItems ? "구매 \(cartItems.count)" : "다음")
                    .typography(.suit17B)
                    .foregroundStyle(hasCartItems ? .white100 : .black100)
                    .padding(4.5)
            }
            .buttonStyle(.glassProminent)
            .tint(hasCartItems ? .black80 : .white100)
        }
    }
}

// MARK: - Mode-Based Views
extension KeyringCustomizingView {
    /// 모드에 따른 씬 뷰
    @ViewBuilder
    private var currentSceneView: some View {
        viewModel.sceneView(for: selectedMode, onSceneReady: {
            withAnimation(.easeIn(duration: 0.4)) {
                isSceneReady = true
            }
            closeLoadingIfReady()
        })
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: selectedMode)
    }

    /// 모드에 따른 하단 콘텐츠 뷰
    @ViewBuilder
    private var currentBottomView: some View {
        viewModel.bottomContentView(
            for: selectedMode,
            showPurchaseSheet: $showPurchaseSheet,
            cartItems: $cartItems
        )
        .opacity(bottomViewOpacity)
        .offset(y: bottomViewOffset)
        .onAppear {
            if isInitialBottomViewAppear {
                // 첫 진입 시에만 애니메이션
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초 딜레이
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                        bottomViewOpacity = 1.0
                        bottomViewOffset = 0
                    }
                }
            } else {
                // 모드 전환 시에는 즉시 표시
                bottomViewOpacity = 1.0
                bottomViewOffset = 0
            }
        }
        .onChange(of: selectedMode) { _, _ in
            if !isInitialBottomViewAppear {
                // 모드 전환 시 상태 초기화 (애니메이션 없이)
                bottomViewOpacity = 1.0
                bottomViewOffset = 0
            }
        }
    }
}

// MARK: - Mode Selection Buttons
extension KeyringCustomizingView {
    /// 모드 선택 버튼
    private func modeButton(for mode: CustomizingMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(selectedMode == mode ? .main500 : .white100)
                    .frame(width: 46, height: 46)
                    .shadow(color: .black.opacity(0.25), radius: 3.83)

                VStack(spacing: 0) {
                    Image(mode.btnImage(isSelected: selectedMode == mode))
                    Text(mode.rawValue)
                        .typography(.suit9B)
                        .foregroundStyle(selectedMode == mode ? .white100 : .gray400)
                }
                .padding(.top, 6.54)
                .padding(.bottom, 3.66)
            }
        }
        .scaleEffect(selectedMode == mode ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedMode)
    }
}
