//
//  MyPageViewModel.swift
//  Keychy
//
//  Created by 길지훈 12/15/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@Observable
class MyPageViewModel {
    // MARK: - Alert States

    /// 설정 Alert 표시 여부
    var showSettingsAlert = false

    /// Alert 타입
    var alertType: AlertType = .turnOn

    /// 로그아웃 Alert
    var showLogoutAlert = false
    var logoutAlertScale: CGFloat = 0.3

    /// 회원탈퇴 Alert
    var showDeleteAccountAlert = false
    var deleteAccountAlertScale: CGFloat = 0.3

    /// 재인증 필요 Alert
    var showReauthAlert = false

    /// 로딩 Alert
    var showLoadingAlert = false
    var loadingAlertScale: CGFloat = 0.3

    // MARK: - Notification States

    /// 푸시 알림 활성화 여부
    var isPushNotificationEnabled = false

    /// 마케팅 알림 활성화 여부
    var isMarketingNotificationEnabled = false

    // MARK: - Apple Sign In States

    /// Apple Sign In 재인증용 Nonce
    var currentNonce: String?

    /// Apple Auth Coordinator
    var authCoordinator: AppleAuthCoordinator?

    /// Apple Sign In 시트 표시 여부
    var isShowingAppleSignIn = false

    // MARK: - Private Properties

    private let notificationManager = NotificationManager.shared
    private let db = Firestore.firestore()

    // MARK: - Alert Type

    enum AlertType {
        case turnOn
        case turnOff

        var title: String {
            switch self {
            case .turnOn:
                return "알림 권한이 필요해요"
            case .turnOff:
                return "알림을 끄시겠어요?"
            }
        }

        var message: String {
            switch self {
            case .turnOn:
                return "설정에서 알림을 켜주세요"
            case .turnOff:
                return "설정에서 알림을 끌 수 있어요"
            }
        }
    }

    // MARK: - Notification Methods

    /// 알림 권한 체크 (초기화용)
    func checkNotificationPermission() {
        notificationManager.checkPermission { [weak self] isAuthorized in
            self?.isPushNotificationEnabled = isAuthorized
        }
    }

    /// 전체 알림 토글 변경 처리
    func handlePushNotificationToggle(newValue: Bool) {
        notificationManager.checkPermission { [weak self] isAuthorized in
            guard let self = self else { return }

            if newValue {
                // 토글 ON 시도
                if isAuthorized {
                    // 이미 허용됨
                    self.isPushNotificationEnabled = true
                } else {
                    // 권한 없음 -> 권한 요청
                    self.notificationManager.requestPermission { granted in
                        if granted {
                            self.isPushNotificationEnabled = true
                        } else {
                            // 권한 거부됨 -> 설정 이동 Alert
                            self.alertType = .turnOn
                            self.showSettingsAlert = true
                        }
                    }
                }
            } else {
                // 토글 OFF 시도
                if isAuthorized {
                    // 현재 권한이 있는 상태에서 끄려고 함 -> 설정으로 안내 (끄기)
                    self.alertType = .turnOff
                    self.showSettingsAlert = true
                } else {
                    // 이미 꺼진 상태 -> 그대로 유지
                    self.isPushNotificationEnabled = false
                }
            }
        }
    }

    /// 마케팅 정보 알림 토글 변경 처리
    func handleMarketingToggle(newValue: Bool, userManager: UserManager) {
        // 전체 알림이 꺼져있으면 아무것도 안함
        guard isPushNotificationEnabled else {
            return
        }

        // Firestore에 마케팅 동의 저장
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("User")
            .document(uid)
            .updateData(["marketingAgreed": newValue]) { [weak self] error in
                if let error = error {
                    print("마케팅 알림 설정 저장 실패: \(error.localizedDescription)")
                    // 실패 시 원래대로 되돌리기
                    DispatchQueue.main.async { [weak self] in
                        self?.isMarketingNotificationEnabled = !newValue
                    }
                } else {
                    print("마케팅 알림 설정 저장 성공: \(newValue)")
                    // UserManager의 currentUser도 즉시 업데이트
                    DispatchQueue.main.async {
                        if var user = userManager.currentUser {
                            user.marketingAgreed = newValue
                            userManager.currentUser = user
                            userManager.saveToCache()
                        }
                    }
                }
            }
    }

    // MARK: - Logout

    /// 로그아웃
    func logout(userManager: UserManager, introViewModel: IntroViewModel) {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }

        do {
            // 1. Firebase Auth 로그아웃
            try Auth.auth().signOut()

            // 2. UserManager 초기화
            userManager.clearUserInfo()

            // 3. 로그인 상태 변경 → RootView가 자동으로 IntroView로 전환
            introViewModel.isLoggedIn = false
            introViewModel.needsProfileSetup = false
        } catch {
            // 로그아웃 실패 처리
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Account

    /// 회원탈퇴
    func deleteAccount(userManager: UserManager, introViewModel: IntroViewModel) {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }

        guard let user = Auth.auth().currentUser else {
            return
        }

        let uid = user.uid

        // LoadingAlert 표시
        showLoadingAlert = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            loadingAlertScale = 1.0
        }

        // 1. 먼저 Firebase Auth 계정 삭제 시도 (재인증 필요 여부 확인)
        user.delete { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                // LoadingAlert 숨기기
                self.hideLoadingAlert()

                // 재인증 필요 에러 처리
                let nsError = error as NSError
                if nsError.code == 17014 { // FIRAuthErrorCodeRequiresRecentLogin
                    self.showReauthAlert = true
                }
            } else {
                // 2. Auth 삭제 성공 → Firestore 데이터 삭제
                userManager.deleteUserData(uid: uid) { [weak self] result in
                    guard let self = self else { return }

                    // LoadingAlert 숨기기
                    self.hideLoadingAlert()

                    // 3. UserManager 초기화 및 로그인 화면으로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        userManager.clearUserInfo()  // 로컬 캐시 정리
                        introViewModel.isLoggedIn = false
                        introViewModel.needsProfileSetup = false
                    }
                }
            }
        }
    }

    /// 재인증 후 회원탈퇴 진행
    func deleteAccountAfterReauth(user: FirebaseAuth.User, userManager: UserManager, introViewModel: IntroViewModel) {
        let uid = user.uid

        // 1. Firebase Auth 계정 삭제
        user.delete { [weak self] error in
            guard let self = self else { return }

            if error != nil {
                // LoadingAlert 숨기기
                self.hideLoadingAlert()
            } else {
                // 2. Auth 삭제 성공 → Firestore 데이터 삭제
                userManager.deleteUserData(uid: uid) { [weak self] result in
                    guard let self = self else { return }

                    // LoadingAlert 숨기기
                    self.hideLoadingAlert()

                    // 3. UserManager 초기화 및 로그인 화면으로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        userManager.clearUserInfo()  // 로컬 캐시 정리
                        introViewModel.isLoggedIn = false
                        introViewModel.needsProfileSetup = false
                    }
                }
            }
        }
    }

    // MARK: - Apple Reauthentication

    /// Apple Sign In 재인증
    func startReauthentication(userManager: UserManager, introViewModel: IntroViewModel) {
        let nonce = randomNonceString()
        currentNonce = nonce

        // Apple Sign In 시트 표시 시작 → 네비게이션 바 숨김
        isShowingAppleSignIn = true

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        // Coordinator 생성 및 저장
        let coordinator = AppleAuthCoordinator(
            nonce: nonce,
            onSuccess: { [weak self] credential in
                self?.isShowingAppleSignIn = false
                self?.handleReauthSuccess(credential: credential, userManager: userManager, introViewModel: introViewModel)
            },
            onFailure: { [weak self] error in
                // Apple 재인증 취소 또는 실패 → 네비게이션 바 복원
                self?.isShowingAppleSignIn = false
            }
        )
        authCoordinator = coordinator

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.performRequests()
    }

    /// 재인증 성공 처리
    func handleReauthSuccess(credential: AuthCredential, userManager: UserManager, introViewModel: IntroViewModel) {
        guard let user = Auth.auth().currentUser else {
            return
        }

        // LoadingAlert 표시
        showLoadingAlert = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            loadingAlertScale = 1.0
        }

        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }

            if error != nil {
                // LoadingAlert 숨기기
                self.hideLoadingAlert()
            } else {
                // 재인증 성공 → 회원탈퇴 진행
                self.deleteAccountAfterReauth(user: user, userManager: userManager, introViewModel: introViewModel)
            }
        }
    }

    // MARK: - Helper Methods

    /// LoadingAlert 숨기기
    private func hideLoadingAlert() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            loadingAlertScale = 0.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showLoadingAlert = false
        }
    }

    // MARK: - Nonce & SHA256 Utilities

    /// 보안용 Nonce 생성
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

    /// SHA256 해시
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
