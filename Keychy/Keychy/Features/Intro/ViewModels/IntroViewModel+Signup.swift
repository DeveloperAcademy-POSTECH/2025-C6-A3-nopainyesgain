//
//  IntroViewModel+Signup.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

// MARK: - 회원가입 처리
extension IntroViewModel {
    
    // 회원가입 처리
    func handleSignUp(user: FirebaseAuth.User, appleIDCredential: ASAuthorizationAppleIDCredential) {
        print("신규 사용자 회원가입")

        // 이메일 추출
        let email = appleIDCredential.email ?? user.email ?? ""
        print("이메일: \(email.isEmpty ? "없음" : email)")

        DispatchQueue.main.async { [weak self] in
            self?.tempUserUID = user.uid
            self?.tempUserEmail = email
            // 신규 가입 시 약관 동의 먼저 표시
            self?.showTermsSheet = true
            self?.needsProfileSetup = false
            self?.isLoggedIn = false
        }
    }
    
    // 프로필 저장
    func saveProfile(nickname: String) {
        if tempUserUID.isEmpty {
            if let currentUser = Auth.auth().currentUser {
                tempUserUID = currentUser.uid
                tempUserEmail = currentUser.email ?? ""
            } else {
                errorMessage = "사용자 정보를 찾을 수 없음"
                return
            }
        }
        isLoading = true
        errorMessage = nil

        // KeychyUser 객체 생성
        let newUser = KeychyUser(
            id: tempUserUID,
            nickname: nickname,
            email: tempUserEmail
        )

        UserManager.shared.saveProfile(user: newUser) { [weak self] success in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                if success {
                    // 약관 동의 정보 저장
                    self.saveTermsAgreement(marketingAgreed: self.tempMarketingAgreed)

                    // 임시 정보 초기화 및 메인으로 이동
                    self.needsProfileSetup = false
                    self.isLoggedIn = true
                    self.tempUserUID = ""
                    self.tempUserEmail = ""
                    self.tempMarketingAgreed = false
                } else {
                    self.errorMessage = "프로필 저장 실패"
                }
            }
        }

    }
}
