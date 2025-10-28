//
//  IntroView.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit

// 로그인 뷰
struct IntroView: View {
    @Bindable var viewModel: IntroViewModel
    
    var body: some View {
        loginSection
    }
}

// MARK: - Login Section
extension IntroView {
    private var loginSection: some View {
        
        // TODO: Hi-fi 나오면 디자인 반영할 것
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView("로그인 중...")
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // TODO: HIG 맞춰서 버튼 디자인 수정 필요
            SignInWithAppleButton(
                onRequest: { request in
                    viewModel.configureRequest(request)
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        viewModel.handleSignInWithApple(authorization: authorization)
                    case .failure(let error):
                        viewModel.handleSignInFailure(error)
                    }
                }
            )
            .frame(height: 55)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    IntroView(viewModel: IntroViewModel())
}
