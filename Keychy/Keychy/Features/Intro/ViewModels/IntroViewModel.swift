//
//  IntroViewModel.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

@Observable
class IntroViewModel: NSObject, ASAuthorizationControllerDelegate {
    // 로그인 관련
    var isLoggedIn = false
    var isLoading = false
    var errorMessage: String?
    var currentNonce: String?

    // 프로필 설정 관련
    var needsProfileSetup = false
    var tempUserUID: String = ""
    var tempUserEmail: String = ""
    var tempMarketingAgreed: Bool = false

    // 약관 동의 관련
    var showTermsSheet = false

    // MARK: - 약관 동의 완료
    func completeTermsAgreement(marketingAgreed: Bool) {
        showTermsSheet = false

        // 신규 사용자인지 확인 (tempUserUID가 있으면 신규)
        if !tempUserUID.isEmpty {
            // 신규 사용자 → 약관 동의 정보 저장하고 닉네임 입력으로
            tempMarketingAgreed = marketingAgreed
            needsProfileSetup = true
        } else {
            // 기존 사용자 → Firestore에 약관 동의 저장하고 메인으로
            saveTermsAgreement(marketingAgreed: marketingAgreed)
            isLoggedIn = true
        }
    }

    // MARK: - 약관 동의 저장
    func saveTermsAgreement(marketingAgreed: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("User")
            .document(uid)
            .updateData([
                "termsAgreed": true,              // 필수 약관 동의
                "marketingAgreed": marketingAgreed // 마케팅 수신 동의
            ]) { error in
                if let error = error {
                    print("약관 동의 저장 실패: \(error.localizedDescription)")
                } else {
                    print("약관 동의 저장 성공 - 마케팅: \(marketingAgreed)")
                }
            }
    }
    
    // MARK: - 초기화
    override init() {
        super.init()
    }
    
    // MARK: - Auth 상태 확인
    func checkAuthStatus() {
        guard let user = Auth.auth().currentUser else {
            print("로그인 안 됨")
            isLoggedIn = false
            needsProfileSetup = false
            return
        }
        
        print("Auth 상태 확인: \(user.uid)")
        // Firestore에서 프로필 완성 여부 확인 (닉네임 비어있는지 체크)
        checkProfileCompletion(uid: user.uid)
    }
    
    // MARK: - 프로필 완성 여부 확인
    func checkProfileCompletion(uid: String) {
        UserManager.shared.loadUserInfo(uid: uid) { [weak self] hasProfile in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if hasProfile {
                    // 프로필 완성 → 메인 진입
                    print("프로필 완성됨 → 메인 진입")
                    self.isLoggedIn = true
                    self.needsProfileSetup = false
                } else {
                    // 프로필 미완성 → 닉네임 입력
                    print("프로필 미완성 (닉네임 없음) → 닉네임 입력 화면")
                    self.handleIncompleteProfile(uid: uid)
                }
            }
        }
    }
    
    // MARK: - 미완성 프로필 처리
    func handleIncompleteProfile(uid: String) {
        self.needsProfileSetup = true
        self.isLoggedIn = false
        self.tempUserUID = uid
        
        // 이메일은 Auth에서 가져오기
        if let email = Auth.auth().currentUser?.email {
            self.tempUserEmail = email
        }
    }

    // MARK: - Apple 로그인 시작 (커스텀 버튼용)
    func startAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }

    // MARK: - Apple 로그인 요청 설정 (기존 - 사용 안함)
    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
    }

    // MARK: - 로그인 실패 처리
    func handleSignInFailure(_ error: Error) {
        // TODO: 이후 로그인 화면 나오면 UI & 로직 수정 필요
        errorMessage = "로그인에 실패했습니다. 다시 시도해주세요."
        isLoading = false
    }
    
    // MARK: - 보안용 Nonce 생성
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension IntroViewModel {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // 로그인 성공
        handleSignInWithApple(authorization: authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // 로그인 실패
        handleSignInFailure(error)
    }
}
