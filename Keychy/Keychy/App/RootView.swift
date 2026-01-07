//
//  RootView.swift
//  Keychy
//
//  Created on 12/23/24.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    // MARK: - Constants
    private enum UserDefaultsKey {
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    private enum Delay {
        static let minimumSplash: TimeInterval = 1.5
    }

    // MARK: - Properties
    @State private var introViewModel = IntroViewModel()
    @State private var userManager = UserManager.shared
    @State private var purchaseManager = PurchaseManager.shared
    @State private var isCheckingAuth = true

    // MARK: - Body
    var body: some View {
        Group {
            if isCheckingAuth {
                SplashView()
                    .onAppear {
                        checkAuthAndNavigate()
                    }
            } else {
                currentView
            }
        }
        .background(.gray800)
    }

    // MARK: - Views
    @ViewBuilder
    private var currentView: some View {
        if introViewModel.showAppGuiding {
            IntroAppGuidingView(viewModel: introViewModel)
        } else if introViewModel.showProfileComplete {
            ProfileSetupCompleteView(viewModel: introViewModel)
        } else if introViewModel.needsProfileSetup {
            ProfileSetupView(viewModel: introViewModel)
        } else if introViewModel.isLoggedIn {
            MainTabView()
                .environment(userManager)
                .environment(introViewModel)
        } else {
            IntroView(viewModel: introViewModel)
        }
    }

    // MARK: - Methods
    /// 인증 상태 확인 및 적절한 화면으로 라우팅
    /// - 최소 스플래시 시간 보장
    /// - Firebase 인증 세션 확인
    /// - 프로필 존재 여부에 따라 화면 분기
    private func checkAuthAndNavigate() {
        let startTime = Date()

        // 첫 설치 여부 확인
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: UserDefaultsKey.hasLaunchedBefore)

        if let user = Auth.auth().currentUser, hasLaunchedBefore {
            // 기존 사용자 + 로그인 세션 있음 → 자동 로그인
            // Firebase에서 유저 프로필 확인
            UserManager.shared.loadUserInfo(uid: user.uid) { hasProfile in
                let elapsed = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, Delay.minimumSplash - elapsed)

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(remainingTime))

                    if hasProfile {
                        // 프로필 있음 → 메인 화면
                        introViewModel.isLoggedIn = true
                        introViewModel.needsProfileSetup = false

                        // 백그라운드에서 구매한 이펙트 동기화
                        Task.detached(priority: .background) {
                            await EffectSyncManager.shared.syncPurchasedEffects(userId: user.uid)
                        }
                    } else {
                        // 프로필 없음 → 약관 동의부터 시작 (신규 가입 플로우)
                        introViewModel.tempUserUID = user.uid
                        introViewModel.tempUserEmail = user.email ?? ""
                        introViewModel.isLoggedIn = false
                        introViewModel.needsProfileSetup = false
                        introViewModel.showTermsSheet = true  // 약관 동의 시트 표시
                    }
                    isCheckingAuth = false
                }
            }
        } else {
            // 첫 설치 또는 로그인 세션 없음 → 로그인 화면
            let elapsed = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, Delay.minimumSplash - elapsed)

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(remainingTime))

                // 첫 실행 플래그 저장 (이후부턴 자동 로그인 가능)
                if !hasLaunchedBefore {
                    UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasLaunchedBefore)
                }

                introViewModel.isLoggedIn = false
                introViewModel.needsProfileSetup = false
                isCheckingAuth = false
            }
        }
    }
}
