//
//  IntroViewModel+NicknameSetup.swift
//  Keychy
//
//  Created by Jini on 10/28/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - 닉네임 설정 관련
extension IntroViewModel {

    // MARK: - 닉네임 기본 유효성 검사
    func isValidNickname(_ nickname: String, maxLength: Int = 10) -> Bool {
        // 빈 문자열 체크
        if nickname.isEmpty {
            return false
        }

        // 1-10자 제한
        if nickname.count > maxLength {
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

    // MARK: - 유효성 검사 및 메시지 업데이트
    func validateNickname(_ nickname: String) {
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

    // MARK: - Firebase에서 닉네임 중복 확인
    func checkNicknameDuplicate(_ nickname: String) {
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
