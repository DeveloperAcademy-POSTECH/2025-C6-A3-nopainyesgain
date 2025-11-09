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
        ZStack {
            logoSection
            
            VStack(spacing: 0) {
                Spacer()
                
                loadingAndError
                
                /// 애플 로그인 버튼
                appleLoginBtn
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray800)
    }
}

// MARK: - Login Section
extension IntroView {
    /// 로고
    private var logoSection: some View {
        VStack(spacing: 20) {
            Image("introIcon")
            Image("introTypo")
        }
    }
    
    /// 로그인 로딩
    private var loadingAndError: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView("로그인 중")
                    .typography(.suit13M)
            }
            if viewModel.errorMessage != nil {
                Text("다시 시도해주세요.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    /// 애플 로그인 버튼 (커스텀)
    private var appleLoginBtn: some View {
        Button {
            viewModel.startAppleSignIn()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Sign in with Apple")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 334, height: 48)
            .cornerRadius(24)
        }
        .buttonStyle(.glassProminent)
        .tint(.white)
        .foregroundStyle(.black)
    }
    
    /// 이용약관 동의 시트
//    private var termsSheet: some View {
//        
//    }
}


