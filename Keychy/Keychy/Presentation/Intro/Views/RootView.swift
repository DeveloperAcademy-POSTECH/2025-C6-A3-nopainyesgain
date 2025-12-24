//
//  RootView.swift
//  Keychy
//
//  Created on 12/23/24.
//

import SwiftUI

/// 앱의 최상위 뷰 - 인증 상태에 따라 적절한 화면을 표시
struct RootView: View {
    // MARK: - Properties
    @State private var viewModel = RootViewModel()

    // MARK: - Body
    var body: some View {
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
        case .login:
            IntroView(viewModel: viewModel.introViewModel)
        }
    }
}
