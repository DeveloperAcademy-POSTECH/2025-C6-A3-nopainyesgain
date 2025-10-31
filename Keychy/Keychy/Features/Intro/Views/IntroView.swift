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
            Spacer()
            
            if viewModel.isLoading {
                ProgressView("로그인 중...")
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // TODO: HIG 맞춰서 버튼 디자인 수정 필요
            HStack(spacing: 12) {
                
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Sign in with Apple")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(width: 334, height: 48)
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
            .background(Color.black)
            .cornerRadius(256)
            .padding(.horizontal, 34)
            .padding(.bottom, 32)

        }
        .overlay(
            VStack(spacing: 20) {
                Image("appIcon")
                    .resizable()
                    .frame(width: 100, height: 100)
                
                Image("logoType")
                    .resizable()
                    .frame(width: 98, height: 20)
            }
        )
    }
}

#Preview {
    IntroView(viewModel: IntroViewModel())
}
