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
            self?.needsProfileSetup = true
        }
    }
    
    // 프로필 저장
    func saveProfile(nickname: String) {
        guard !tempUserUID.isEmpty else {
            errorMessage = "사용자 정보를 찾을 수 없음"
            return
        }
        
        print("사용자 입력 닉네임 저장: \(nickname)")
        isLoading = true
        errorMessage = nil
        
        UserManager.shared.saveProfile(
            uid: tempUserUID,
            nickname: nickname,
            email: tempUserEmail
        ) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.needsProfileSetup = false
                    self.isLoggedIn = true
                    self.tempUserUID = ""
                    self.tempUserEmail = ""
                } else {
                    self.errorMessage = "프로필 저장 실패"
                }
            }
        }

    }
}
