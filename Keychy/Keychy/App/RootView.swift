//
//  RootView.swift
//  Keychy
//
//  Created on 12/23/24.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var introViewModel = IntroViewModel()
    @State private var userManager = UserManager.shared
    @State private var purchaseManager = PurchaseManager.shared
    @State private var isCheckingAuth = true

    var body: some View {
        Group {
            if isCheckingAuth {
                SplashView()
                    .onAppear {
                        // 스플래시 표시하면서 유저 확인
                        checkAuthAndNavigate()
                    }
            } else {
                // 유저 상태에 따라 화면 전환
                if introViewModel.showAppGuiding {
                    // 앱 가이드 화면
                    IntroAppGuidingView(viewModel: introViewModel)
                } else if introViewModel.showProfileComplete {
                    // 프로필 완료 화면
                    ProfileSetupCompleteView(viewModel: introViewModel)
                } else if introViewModel.needsProfileSetup {
                    // 프로필 설정 필요
                    ProfileSetupView(viewModel: introViewModel)
                } else if introViewModel.isLoggedIn {
                    // 로그인 완료 → 메인 화면
                    MainTabView()
                        .environment(userManager)
                        .environment(introViewModel)
                } else {
                    // 로그인 필요 → 로그인 화면
                    IntroView(viewModel: introViewModel)
                }
            }
        }
        .background(.gray800)
    }

    private func checkAuthAndNavigate() {
        let minimumSplashTime: TimeInterval = 1.5 // 최소 1.5초 스플래시 표시
        let startTime = Date()

        // 첫 설치 여부 확인
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

        if let user = Auth.auth().currentUser, hasLaunchedBefore {
            // 기존 사용자 + 로그인 세션 있음 → 자동 로그인
            // Firebase에서 유저 프로필 확인
            UserManager.shared.loadUserInfo(uid: user.uid) { hasProfile in
                let elapsed = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, minimumSplashTime - elapsed)

                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
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
            let remainingTime = max(0, minimumSplashTime - elapsed)

            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                // 첫 실행 플래그 저장 (이후부턴 자동 로그인 가능)
                if !hasLaunchedBefore {
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }

                introViewModel.isLoggedIn = false
                introViewModel.needsProfileSetup = false
                isCheckingAuth = false
            }
        }
    }
}
