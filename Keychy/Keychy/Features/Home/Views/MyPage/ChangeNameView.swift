//
//  ChangeNameView.swift
//  Keychy
//
//  Created by 길지훈 on 11/6/25.
//

import SwiftUI
import FirebaseFirestore

// 닉네임 변경 뷰
struct ChangeNameView: View {
    @Environment(UserManager.self) private var userManager
    @Bindable var router: NavigationRouter<HomeRoute>

    @State private var nickname: String = ""
    @State private var validationMessage: String = "영문, 숫자, 한글만 입력 가능해요."
    @State private var isValidationPositive: Bool = false
    @State private var validationTask: Task<Void, Never>?
    @State private var isCheckingDuplicate: Bool = false

    // 성공 Alert
    @State private var showSuccessAlert = false
    @State private var isUpdating = false

    private let maxNicknameLength = 9
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("닉네임")
                        .typography(.suit16B)
                        .padding(.top, 37)
                    
                    HStack {
                        TextField("닉네임을 적어주세요.", text: $nickname)
                            .typography(.notosans15M)
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
                                    validationMessage = "영문, 숫자, 한글만 입력 가능해요."
                                    isValidationPositive = false
                                } else {
                                    validationMessage = "영문, 숫자, 한글만 입력 가능해요."
                                    isValidationPositive = false
                                }
                                
                                // 2초 후 유효성 검사
                                validationTask = Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000)
                                    
                                    if !Task.isCancelled {
                                        await MainActor.run {
                                            validateNickname(newValue)
                                        }
                                    }
                                }
                            }
                        
                        // 글자수 표시
                        if isCheckingDuplicate {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("\(nickname.count)/\(maxNicknameLength)")
                                .typography(.suit13M)
                                .foregroundColor(.gray300)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray50)
                    )
                    
                    // 유효성 메시지
                    Text(validationMessage)
                        .typography(.suit14M)
                        .foregroundColor(
                            isValidationPositive ? .gray400 :
                                (validationMessage == "영문, 숫자, 한글만 입력 가능해요." ? .gray400 : .red)
                        )
                }
                
                Spacer()
                
                Button {
                    if isNicknameValid {
                        updateNickname()
                    }
                } label: {
                    Text("변경")
                        .typography(.suit17B)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7.5)
                }
                .buttonStyle(.glassProminent)
                .tint(isNicknameValid ? .main500 : .black20)
                .foregroundStyle(isNicknameValid ? .white100 : .black40)
                .disabled(!isNicknameValid)
                .animation(.easeInOut(duration: 0.2), value: isNicknameValid)
                .onAppear {
                    // 현재 닉네임으로 초기화
                    nickname = userManager.currentUser?.nickname ?? ""
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle("닉네임 변경")
            .toolbar(.hidden, for: .tabBar)
            .dismissKeyboardOnTap()
            .ignoresSafeArea(.keyboard)

            // 업데이트 중 로딩
            if isUpdating {
                LoadingAlert(type: .short, message: nil)
            }

            // 성공 Alert
            if showSuccessAlert {
                KeychyAlert(
                    type: .checkmark,
                    message: "닉네임이 변경되었습니다.",
                    isPresented: $showSuccessAlert
                )
            }
        }
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
        
        // 1-9자 제한
        if nickname.count > maxNicknameLength {
            return false
        }
        
        // 공백 포함 체크
        if nickname.contains(" ") {
            return false
        }
        
        // 영문, 숫자, 한글만 허용 (공백 제외)
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ"))
        
        if nickname.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return false
        }
        
        return true
    }
    
    // 유효성 검사 및 메시지 업데이트 (2초 후 실행)
    private func validateNickname(_ nickname: String) {
        if nickname.isEmpty {
            validationMessage = "영문, 숫자, 한글만 입력 가능해요."
            isValidationPositive = false
            return
        }
        
        // 공백 체크
        if nickname.contains(" ") {
            validationMessage = "공백은 사용할 수 없어요"
            isValidationPositive = false
            return
        }
        
        // 특수문자 체크
        let allowedCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ"))

        if nickname.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            validationMessage = "영문, 숫자, 한글만 입력 가능해요."
            isValidationPositive = false
            return
        }

        // 욕설 체크
        let profanityCheck = TextFilter.shared.validateText(nickname)
        if !profanityCheck.isValid {
            validationMessage = profanityCheck.message ?? "부적절한 단어가 포함되어 있어요"
            isValidationPositive = false
            return
        }

        // Firebase 중복 확인
        checkNicknameDuplicate(nickname)
    }
    
    // Firebase에서 닉네임 중복 확인
    private func checkNicknameDuplicate(_ nickname: String) {
        // 현재 닉네임과 같으면 버튼 비활성화
        if nickname == userManager.currentUser?.nickname {
            validationMessage = "현재 사용 중인 닉네임이에요"
            isValidationPositive = false
            isCheckingDuplicate = false
            return
        }

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

    // 닉네임 변경 함수
    private func updateNickname() {
        guard let currentUser = userManager.currentUser else { return }

        // 기존 닉네임과 같으면 그냥 뒤로가기
        if nickname == currentUser.nickname {
            router.pop()
            return
        }

        // 로딩 시작
        isUpdating = true

        // Firebase 업데이트
        let db = Firestore.firestore()
        db.collection("User").document(currentUser.id)
            .updateData(["nickname": nickname]) { error in
                DispatchQueue.main.async {
                    // 로딩 종료
                    isUpdating = false

                    if error == nil {
                        // 성공 Alert 표시
                        showSuccessAlert = true

                        // UserManager 업데이트
                        userManager.loadUserInfo(uid: currentUser.id) { _ in }

                        // 2초 후 뒤로가기 (KeychyAlert duration이 2초)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                            router.pop()
                        }
                    }
                }
            }
    }

}
