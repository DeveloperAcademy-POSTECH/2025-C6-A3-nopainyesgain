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
    @State private var isAllChecked: Bool = false
    @State private var isTermsChecked: Bool = false      // 개인정보 처리방침 (필수)
    @State private var isMarketingChecked: Bool = false  // 마케팅 수신 동의 (선택)
    @State private var showTermsDetail: Bool = false     // 약관 상세보기 시트

    // 필수 항목 모두 동의 여부 (버튼 활성화 조건)
    private var canProceed: Bool {
        isTermsChecked  // 필수만 체크하면 됨
    }

    @State private var showButton: Bool = false

    var body: some View {
        ZStack {
            logoSection
            VStack(spacing: 0) {
                Spacer()

                loadingAndError

                /// 애플 로그인 버튼
                appleLoginBtn
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)
            }
            .sheet(isPresented: $viewModel.showTermsSheet) {
                termsSheet
                    .sheet(isPresented: $showTermsDetail) {
                        TermsView(router: nil)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray800)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                showButton = true
            }
        }
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
                Text("로그인에 실패했습니다. 다시 시도해주세요.")
                    .typography(.suit14M)
                    .foregroundColor(.white100)
                    
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
            Image(isAllChecked ? "checkedBox" : "uncheckedBox")
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
        .onTapGesture {
            toggleAll()
        }
    }
    
    /// 약관 동의 개별 row
    private func termRow(text: String, initial: Bool) -> some View {
        let isChecked = initial ? isTermsChecked : isMarketingChecked

        return HStack(spacing: 0) {
            Button {
                if initial {
                    isTermsChecked.toggle()
                } else {
                    isMarketingChecked.toggle()
                }
                updateAllChecked()
            } label: {
                Image(isChecked ? "checkedBox" : "uncheckedBox")
            }
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
                    showTermsDetail = true
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
            // 마케팅 동의 저장 및 로그인 완료
            viewModel.completeTermsAgreement(marketingAgreed: isMarketingChecked)
        } label: {
            Text("동의합니다")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .typography(.suit17B)
        .buttonStyle(.glassProminent)
        .tint(canProceed ? .main500 : .black20)
        .foregroundStyle(canProceed ? .white100 : .black40)
        .disabled(!canProceed)
    }

    /// 모두 동의 토글
    private func toggleAll() {
        if isAllChecked {
            // 모두 해제
            isTermsChecked = false
            isMarketingChecked = false
            isAllChecked = false
        } else {
            // 모두 선택
            isTermsChecked = true
            isMarketingChecked = true
            isAllChecked = true
        }
    }

    /// 개별 항목 변경 시 "모두 동의" 상태 업데이트
    private func updateAllChecked() {
        isAllChecked = isTermsChecked && isMarketingChecked
    }
}


