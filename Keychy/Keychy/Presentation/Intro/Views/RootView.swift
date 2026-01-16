//
//  RootView.swift
//  Keychy
//
//  Created on 12/23/24.
//

import SwiftUI

/// 앱의 최상위 뷰
/// 업데이트 체크, 인증 상태 확인 후 적절한 화면을 표시
struct RootView: View {
    @State private var viewModel = RootViewModel()

    var body: some View {
        ZStack {
            // 인증 상태에 따른 화면 분기
            Group {
                if viewModel.isCheckingAuth {
                    SplashView()
                        .onAppear {
                            viewModel.checkAuthAndNavigate()
                        }
                } else {
                    currentView
                }
            }
            .background(.gray800)

            // 업데이트 Alert 오버레이
            if viewModel.updateManager.showUpdateAlert {
                updateAlertOverlay
            }
        }
    }

    // MARK: - Views
    @ViewBuilder
    private var currentView: some View {
        switch viewModel.currentState {
        case .appGuiding:
            IntroAppGuidingView(viewModel: viewModel.introViewModel)
        case .profileComplete:
            ProfileSetupCompleteView(viewModel: viewModel.introViewModel)
        case .profileSetup:
            ProfileSetupView(viewModel: viewModel.introViewModel)
        case .main:
            MainTabView()
                .environment(viewModel.userManager)
                .environment(viewModel.introViewModel)
                .onAppear {
                    viewModel.checkActiveReview()
                }
        case .login:
            IntroView(viewModel: viewModel.introViewModel)
        }
    }

    /// 업데이트 Alert 오버레이
    private var updateAlertOverlay: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()

            UpdateAlert(appStoreURL: viewModel.updateManager.appStoreURL)
                .transition(.scale(scale: 0.3).combined(with: .opacity))
        }
        .zIndex(999)
    }
}
