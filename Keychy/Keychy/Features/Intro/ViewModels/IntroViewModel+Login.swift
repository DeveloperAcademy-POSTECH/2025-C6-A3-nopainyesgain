//
//  IntroViewModel+Login.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore

// MARK: - 로그인 처리
extension IntroViewModel {
    
    // MARK: - Apple 로그인 처리
    func handleSignInWithApple(authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Apple 로그인 정보를 가져올 수 없습니다."
            return
        }
        
        // 로그인 정보 로깅 (개발 TEST 끝나면 지우기)
        logAppleCredentialInfo(appleIDCredential)
        
        isLoading = true
        errorMessage = nil
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Firebase 로그인 실패: \(error.localizedDescription)"
                return
            }
            
            guard let user = authResult?.user else { return }
            
            print("Firebase 로그인 성공: \(user.uid)")
            
            // 신규 사용자 여부 확인
            let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
            print("신규 사용자: \(isNewUser)")
            
            if isNewUser {
                // 신규 사용자면 회원가입 처리
                self.handleSignUp(
                    user: user,
                    appleIDCredential: appleIDCredential
                )
            } else {
                // 기존 사용자면 프로필 완성 여부 확인
                self.handleExistingUserLogin(user: user)
            }
        }
        
    }
    
    // MARK: - 기존 사용자 로그인 처리
    private func handleExistingUserLogin(user: FirebaseAuth.User) {
        print("기존 사용자 로그인 처리")

        UserManager.shared.loadUserInfo(uid: user.uid) { [weak self] hasProfile in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if hasProfile {
                    // 약관 동의 여부 체크
                    if let currentUser = UserManager.shared.currentUser, currentUser.termsAgreed {
                        // 이미 약관 동의함 → 바로 메인 화면
                        print("약관 동의 완료 → 메인 화면")
                        self.isLoggedIn = true
                        self.needsProfileSetup = false
                    } else {
                        // 약관 동의 안했음 → 약관 시트 표시
                        print("약관 동의 필요 → 약관 시트 표시")
                        self.showTermsSheet = true
                    }
                } else {
                    // Firestore 문서 없음 → 신규 가입 플로우 (약관 동의부터)
                    print("Firestore 문서 없음 → 약관 동의부터 시작")
                    self.tempUserUID = user.uid
                    self.tempUserEmail = user.email ?? ""
                    self.showTermsSheet = true
                    self.needsProfileSetup = false
                    self.isLoggedIn = false
                }
            }
        }
    }
    
    // MARK: - Apple 로그인 정보 로깅
    private func logAppleCredentialInfo(_ credential: ASAuthorizationAppleIDCredential) {
        print("Apple 로그인 시작 (첫 로그인 시에만 뜸)")
        print("이메일: \(credential.email ?? "없음")")
        print("이름: \(credential.fullName?.givenName ?? "없음") \(credential.fullName?.familyName ?? "없음")")
    }
  
}
