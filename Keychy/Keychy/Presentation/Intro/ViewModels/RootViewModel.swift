//
//  RootViewModel.swift
//  Keychy
//
//  Created on 12/24/24.
//

import SwiftUI
import FirebaseAuth

/// 앱 최상위 라우팅 및 인증 상태 관리
@Observable
class RootViewModel {
    // MARK: - Types
    enum ViewState {
        case appGuiding
        case profileComplete
        case profileSetup
        case main
        case login
    }

    // MARK: - Constants
    private enum UserDefaultsKey {
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    private enum Delay {
        static let minimumSplash: TimeInterval = 0.5
    }

    // MARK: - Properties
    var introViewModel = IntroViewModel()
    var userManager = UserManager.shared
    var purchaseManager = PurchaseManager.shared
    var isCheckingAuth = true

    // MARK: - Computed Properties
    /// 현재 화면 상태
    var currentState: ViewState {
        if introViewModel.showAppGuiding { return .appGuiding }
        if introViewModel.showProfileComplete { return .profileComplete }
        if introViewModel.needsProfileSetup { return .profileSetup }
        if introViewModel.isLoggedIn { return .main }
        return .login
    }

    // MARK: - Methods
    /// 사용자 인증 상태를 확인하고 적절한 화면으로 라우팅
    func checkAuthAndNavigate() {
        let startTime = Date()
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: UserDefaultsKey.hasLaunchedBefore)

        if let user = Auth.auth().currentUser, hasLaunchedBefore {
            handleReturningUser(user, startTime: startTime)
        } else {
            handleFirstVisit(hasLaunchedBefore, startTime: startTime)
        }
    }

    /// 재방문 사용자 처리 - 프로필 확인 후 적절한 화면으로 이동
    private func handleReturningUser(_ user: User, startTime: Date) {
        UserManager.shared.loadUserInfo(uid: user.uid) { hasProfile in
            Task { @MainActor in
                await self.ensureMinimumSplashTime(since: startTime)

                if hasProfile {
                    self.routeToMain(userId: user.uid)
                } else {
                    self.routeToTerms(user: user)
                }
                self.isCheckingAuth = false
            }
        }
    }

    /// 첫 방문 사용자 처리 - 로그인 화면으로 이동
    private func handleFirstVisit(_ hasLaunchedBefore: Bool, startTime: Date) {
        Task { @MainActor in
            await ensureMinimumSplashTime(since: startTime)

            if !hasLaunchedBefore {
                UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasLaunchedBefore)
            }

            routeToLogin()
            isCheckingAuth = false
        }
    }

    /// 최소 스플래시 시간 보장
    private func ensureMinimumSplashTime(since startTime: Date) async {
        let elapsed = Date().timeIntervalSince(startTime)
        let remainingTime = max(0, Delay.minimumSplash - elapsed)
        try? await Task.sleep(for: .seconds(remainingTime))
    }

    /// 메인 화면으로 라우팅
    private func routeToMain(userId: String) {
        introViewModel.isLoggedIn = true
        introViewModel.needsProfileSetup = false

        Task.detached(priority: .background) {
            await EffectSyncManager.shared.syncPurchasedEffects(userId: userId)
        }
    }

    /// 약관 동의 화면으로 라우팅
    private func routeToTerms(user: User) {
        introViewModel.tempUserUID = user.uid
        introViewModel.tempUserEmail = user.email ?? ""
        introViewModel.isLoggedIn = false
        introViewModel.needsProfileSetup = false
        introViewModel.showTermsSheet = true
    }

    /// 로그인 화면으로 라우팅
    private func routeToLogin() {
        introViewModel.isLoggedIn = false
        introViewModel.needsProfileSetup = false
    }
}
