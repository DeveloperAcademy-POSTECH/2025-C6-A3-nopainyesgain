//
//  ChangeNameViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/15/24.
//

import SwiftUI
import FirebaseFirestore

@Observable
class ChangeNameViewModel {
    // MARK: - Properties

    /// 닉네임 입력
    var nickname: String = ""

    /// 유효성 검사 메시지
    var validationMessage: String = "영문, 숫자, 한글만 입력 가능해요."

    /// 유효성 검사 결과 (긍정적인지 여부)
    var isValidationPositive: Bool = false

    /// 중복 확인 중 여부
    var isCheckingDuplicate: Bool = false

    /// 업데이트 중 여부
    var isUpdating: Bool = false

    /// 성공 Alert 표시 여부
    var showSuccessAlert: Bool = false

    /// 유효성 검사 Task (디바운싱용)
    var validationTask: Task<Void, Never>?

    // MARK: - Constants

    let maxNicknameLength = 9

    // MARK: - Computed Properties

    /// 닉네임이 유효한지 여부
    var isNicknameValid: Bool {
        !nickname.isEmpty && isValidationPositive
    }

    // MARK: - Private Properties

    private let db = Firestore.firestore()

    // MARK: - Initialization

    /// 현재 닉네임으로 초기화
    func initialize(currentNickname: String) {
        nickname = currentNickname
    }

    // MARK: - Validation

    /// 닉네임 기본 유효성 검사
    func isValidNickname(_ nickname: String) -> Bool {
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

    /// 유효성 검사 및 메시지 업데이트
    func validateNickname(_ nickname: String) {
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

    /// Firebase에서 닉네임 중복 확인
    func checkNicknameDuplicate(_ nickname: String, currentNickname: String? = nil) {
        // 현재 닉네임과 같으면 버튼 비활성화
        if let currentNickname = currentNickname, nickname == currentNickname {
            validationMessage = "현재 사용 중인 닉네임이에요"
            isValidationPositive = false
            isCheckingDuplicate = false
            return
        }

        isCheckingDuplicate = true

        Task {
            do {
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

    // MARK: - Update

    /// 닉네임 변경
    func updateNickname(userId: String, currentNickname: String, completion: @escaping (Bool) -> Void) {
        // 기존 닉네임과 같으면 성공 처리
        if nickname == currentNickname {
            completion(true)
            return
        }

        // 로딩 시작
        isUpdating = true

        // Firebase 업데이트
        db.collection("User").document(userId)
            .updateData(["nickname": nickname]) { [weak self] error in
                guard let self = self else { return }

                Task { @MainActor in
                    // 로딩 종료
                    self.isUpdating = false

                    if error == nil {
                        // 성공 Alert 표시
                        self.showSuccessAlert = true
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
    }
}
