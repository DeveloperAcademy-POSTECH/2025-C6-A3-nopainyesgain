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
    @State var isChecked: Bool = false
    @State var isInitialTerm: Bool = false
    @State var CanGoNext: Bool = false

    var body: some View {
        ZStack {
            logoSection

            VStack(spacing: 0) {
                Spacer()

                loadingAndError

                /// 애플 로그인 버튼
                appleLoginBtn
            }
            .sheet(isPresented: $viewModel.showTermsSheet) {
                termsSheet
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
                    .foregroundStyle(.white)
            }
            if viewModel.errorMessage != nil {
                Text("다시 시도해주세요.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.bottom, 20)
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
    private var termsSheet: some View {
        VStack {
            Text("이용약관 동의")
                .typography(.suit15B25)
                .foregroundStyle(.gray700)
                .padding(.top, 29)
                .padding(.bottom, 22)
        
            VStack(spacing: 25) {
                termRowAll
                    .padding(.horizontal, 20)
                termRow(text: "개인정보 처리방침 및 이용약관 동의", initial: true)
                termRow(text: "마케팅 정보 수신 동의", initial: false)
            }
            
            Spacer()
            
            agreeBtn
                .padding(.horizontal, 34)
        }
        .background(.white100)
        .presentationDetents(([.height(400)]))
    }
    
    /// 약관 전체 동의 row
    private var termRowAll: some View {
        HStack(spacing: 0) {
            Image("uncheckedBox")
                .padding(.trailing, 15)
            Text("모두 동의합니다.")
                .typography(.suit15SB25)
                .foregroundStyle(.black100)
                .padding(.vertical, 4.5)
                
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(.gray50)
        .clipShape(.rect(cornerRadius: 12))
        
    }
    
    /// 약관 동의 개별 row
    private func termRow(text: String, initial: Bool) -> some View {
        HStack(spacing: 0) {
            Image("uncheckedBox")
                .padding(.trailing, 15)
            Text(text)
                .typography(.suit15M25)
                .foregroundStyle(.gray700)
                .padding(.vertical, 4.5)
                .padding(.trailing, 5)
            
            Text(initial ? "(필수)" : "(선택)")
                .typography(.suit15M25)
                .foregroundStyle(initial ? .main500 : .gray700)
            
            if initial {
                Button {
                    // 현재는 개인정보 처리방침 동의밖에 없어서 바로 연결
                    
                } label: {
                    Image("greaterthan")
                        .padding(.leading, 5)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 34)
    }
    
    /// nextBtn
    private var agreeBtn: some View {
        Button {
            // MARK: - 동의하자!
        } label: {
            Text("동의합니다")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .typography(.suit17B)
        .buttonStyle(.glassProminent)
        .disabled(CanGoNext ? true : false)
    }
    
    
}


