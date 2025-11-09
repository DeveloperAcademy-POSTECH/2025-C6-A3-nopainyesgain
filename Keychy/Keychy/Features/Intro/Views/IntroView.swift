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
        
        VStack(spacing: 20) {
            Spacer()
            
            if viewModel.isLoading {
                ProgressView("로그인 중")
                    .typography(.suit13M)
            }
            
            if viewModel.errorMessage != nil {
                Text("서버 오류: 다시 시도해주세요.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Sign in with Apple")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black100)
            .overlay {
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
                .blendMode(.overlay)
            }
            .frame(width: 334, height: 48)
            .background(.white100)
            .cornerRadius(256)
            .padding(.horizontal, 34)
        }
        .overlay(
            VStack(spacing: 20) {
                Image("introIcon")
                Image("introTypo")
            }
        )
        .background(.gray800)
    }
}

#Preview {
    IntroView(viewModel: IntroViewModel())
}
