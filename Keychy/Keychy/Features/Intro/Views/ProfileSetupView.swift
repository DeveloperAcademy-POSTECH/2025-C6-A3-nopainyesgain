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
    @State private var validationMessage: String = "영문, 숫자, 한글, _, .만 입력 가능해요."
    @State private var isValidationPositive: Bool = false
    @State private var validationTask: Task<Void, Never>?
    @State private var isCheckingDuplicate: Bool = false
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
    }
    
    // 닉네임 유효성 검사
    private var isNicknameValid: Bool {
        !nickname.isEmpty && isValidationPositive
    }
    
    // 닉네임 기본 유효성 검사 함수
    private func isValidNickname(_ nickname: String) -> Bool {
        // 빈 문자열 체크
        if nickname.isEmpty {
            return false
        }

        // 1-10자 제한
        if nickname.count > maxNicknameLength {
            return false
        }

        // 공백 포함 체크
        if nickname.contains(" ") {
            return false
        }

        // 영문, 숫자, 한글, 언더바(_), 온점(.) 허용
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ_."))

        if nickname.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return false
        }

        return true
    }
    
    // 유효성 검사 및 메시지 업데이트
    private func validateNickname(_ nickname: String) {
        // 빈 문자열
        if nickname.isEmpty {
            validationMessage = "영문, 숫자, 한글, _, .만 입력 가능해요."
            isValidationPositive = false
            return
        }

        // 공백 체크
        if nickname.contains(" ") {
            validationMessage = "공백은 사용할 수 없어요"
            isValidationPositive = false
            return
        }

        // 특수문자 체크 (영문, 숫자, 한글, 언더바, 온점만 허용)
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ_."))

        if nickname.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            validationMessage = "특수 문자는 _(언더바), .만 가능해요"
            isValidationPositive = false
            return
        }

        // Firebase 중복 확인
        checkNicknameDuplicate(nickname)
    }
    
    // Firebase에서 닉네임 중복 확인
    private func checkNicknameDuplicate(_ nickname: String) {
        isCheckingDuplicate = true
        
        Task {
            do {
                let db = Firestore.firestore()
                let querySnapshot = try await db.collection("User")
                    .whereField("nickname", isEqualTo: nickname)
                    .getDocuments()
                
                await MainActor.run {
                    isCheckingDuplicate = false
                    
                    if querySnapshot.documents.isEmpty {
                        // 사용 가능
                        validationMessage = "사용 가능한 닉네임이에요."
                        isValidationPositive = true
                        
                    } else {
                        // 중복
                        validationMessage = "이미 사용 중인 닉네임이에요"
                        isValidationPositive = false
                        
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingDuplicate = false
                    validationMessage = "닉네임 확인 중 오류가 발생했어요"
                    isValidationPositive = false
                }
            }
        }
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
    
    /// 닉네임 입력 필드
    private var nicknameInputField: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("닉네임을 입력해주세요.", text: $nickname)
                    .typography(.notosans16R)
                    .foregroundStyle(.black100)
                    .textFieldStyle(.plain)
                    .onChange(of: nickname) { oldValue, newValue in
                        // 글자수 제한
                        if newValue.count > maxNicknameLength {
                            nickname = String(newValue.prefix(maxNicknameLength))
                        }
                        
                        // 기존 검사 Task 취소
                        validationTask?.cancel()
                        
                        // 입력 중일 때는 기본 메시지
                        if !newValue.isEmpty {
                            validationMessage = "영문, 숫자, 한글, _, .만 입력 가능해요."
                            isValidationPositive = false
                        } else {
                            validationMessage = "영문, 숫자, 한글, _, .만 입력 가능해요."
                            isValidationPositive = false
                        }
                        
                        // 0.5초 후 유효성 검사
                        validationTask = Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            
                            if !Task.isCancelled {
                                await MainActor.run {
                                    validateNickname(newValue)
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
                Text(validationMessage)
                    .typography(.suit13M)
                    .foregroundColor(
                        isValidationPositive ? .gray300 :
                            (validationMessage == "영문, 숫자, 한글, _, .만 입력 가능해요." ? .gray300 : .red)
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
    }
    
    
}
