//
//  ProfileSetupView.swift
//  Keychy
//
//  Created by Jini on 10/28/25.
//

import SwiftUI
import FirebaseFirestore

// 첫 실행 시 닉네임 등 설정 뷰
struct ProfileSetupView: View {
    @Bindable var viewModel: IntroViewModel

    @State private var nickname: String = ""
    @State private var validationTask: Task<Void, Never>?
    private let maxNicknameLength = 10
    
    var body: some View {
        VStack(spacing: 0) {
            title
            nicknameInput
            descriptionSection
            Spacer()
            nextBtn
        }
        .padding(.horizontal, 34)
        .toolbar(.hidden, for: .tabBar)
        .dismissKeyboardOnTap()
        .ignoresSafeArea(.keyboard)
        .background(.white100)
    }
}

extension ProfileSetupView {
    /// 타이틀
    private var title: some View {
        Text("키링을 만들어 볼까요?")
            .typography(.suit24B)
            .foregroundStyle(.black100)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 54)
    }
    
    /// 닉네임 입력 (키링 배경 + 카드)
    private var nicknameInput: some View {
        ZStack {
            // 배경 키링 이미지
            Image("nameInputKeyring")
                .resizable()
                .scaledToFit()
            
            // 닉네임 입력 카드
            VStack(spacing: 16) {
                Text("닉네임")
                    .typography(.suit17B)
                    .foregroundStyle(.black100)
                
                nicknameInputField
            }
            .padding(.horizontal, 25)
            .padding(.top, 153)
        }
        .padding(.top, 62)
    }
    
    // 닉네임 유효성 검사
    private var isNicknameValid: Bool {
        !nickname.isEmpty && viewModel.isValidationPositive
    }
    
    /// 닉네임 입력 필드
    private var nicknameInputField: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("닉네임을 입력해주세요.", text: $nickname)
                    .typography(.notosans16R)
                    .foregroundStyle(.black100)
                    .textFieldStyle(.plain)
                    .tint(.main500)
                    .onChange(of: nickname) { oldValue, newValue in
                        // 글자수 제한
                        if newValue.count > maxNicknameLength {
                            nickname = String(newValue.prefix(maxNicknameLength))
                        }
                        
                        // 기존 검사 Task 취소
                        validationTask?.cancel()
                        
                        // 입력 중일 때는 기본 메시지
                        viewModel.validationMessage = "영문, 숫자, 한글, _, .만 입력 가능해요."
                        viewModel.isValidationPositive = false

                        // 0.5초 후 유효성 검사
                        validationTask = Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)

                            if !Task.isCancelled {
                                await MainActor.run {
                                    viewModel.validateNickname(newValue)
                                }
                            }
                        }
                    }
                
                
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray50)
            )
            
            // 유효성 메시지
            HStack {
                Text(viewModel.validationMessage)
                    .typography(.suit13M)
                    .foregroundColor(
                        viewModel.isValidationPositive ? .gray300 :
                            (viewModel.validationMessage == "영문, 숫자, 한글, _, .만 입력 가능해요." ? .gray300 : .red)
                    )

                Spacer()

                // 글자수 표시
                Text("\(nickname.count)/\(maxNicknameLength)")
                    .typography(.suit13M)
                    .foregroundColor(.gray300)
            }
        }
    }
    
    /// 하단 설명
    private var descriptionSection: some View {
        Text("입력된 닉네임으로 환영 키링이 만들어져요.\n이 키링은 수정이 불가능하니 신중히 입력해주세요.")
            .typography(.suit15M)
            .foregroundStyle(.gray500)
            .multilineTextAlignment(.center)
            .padding(.top, 15)
    }
    
    /// 다음 버튼
    private var nextBtn: some View {
        Button {
            if isNicknameValid {
                viewModel.saveProfile(nickname: nickname)
            }
        } label: {
            Text("다음")
                .typography(.suit17B)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(isNicknameValid ? .main500 : .black20)
        .foregroundStyle(isNicknameValid ? .white100 : .black40)
        .disabled(!isNicknameValid)
        .animation(.easeInOut(duration: 0.2), value: isNicknameValid)
        .adaptiveBottomPadding()
    }
}
