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
    
    // 닉네임 입력 완료 (Firestore 저장 없이 ProfileCompleteView로 이동)
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

        // Firestore 저장 없이 닉네임만 저장하고 다음 화면으로
        welcomeNickname = nickname
        needsProfileSetup = false
        showProfileComplete = true
    }

    // 프로필 실제 저장 (ProfileCompleteView의 "다음" 버튼에서 호출)
    func saveProfileToFirestore(completion: @escaping (Bool) -> Void) {
        var newUser = KeychyUser(
            id: tempUserUID,
            nickname: welcomeNickname,
            email: tempUserEmail
        )
        newUser.termsAgreed = true
        newUser.marketingAgreed = tempMarketingAgreed

        UserManager.shared.saveProfile(user: newUser) { success in
            completion(success)
        }
    }
}
