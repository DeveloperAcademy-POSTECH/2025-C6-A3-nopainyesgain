//
//  UserManager.swift
//  Keychy
//
//  Created by Jini on 10/28/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@Observable
class UserManager {
    static let shared = UserManager()

    /// 유저 모델
    var currentUser: KeychyUser?

    var isLoaded: Bool = false

    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?

    // Apple Sign In 재인증용
    var currentNonce: String?
    var authCoordinator: AppleAuthCoordinator?

    // 편의 접근 프로퍼티
    var userUID: String { currentUser?.id ?? "" }
    var userNickname: String { currentUser?.nickname ?? "" }
    var userEmail: String { currentUser?.email ?? "" }

    private init() {
        loadFromCache()
    }

    // MARK: - Firestore에 프로필 저장
    func saveProfile(user: KeychyUser, completion: @escaping (Bool) -> Void) {
        let userData = user.toDictionary()

        db.collection("User").document(user.id).setData(userData, merge: true) { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }

            if error != nil {
                completion(false)
            } else {
                // 저장 성공 시 로컬 상태 업데이트
                self.currentUser = user
                self.isLoaded = true
                self.saveToCache()
                completion(true)
            }
        }
    }
    
    // MARK: - Firebase에서 프로필 로드
    func loadUserInfo(uid: String, completion: @escaping (Bool) -> Void) {
        db.collection("User").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }

            if error != nil {
                completion(false)
                return
            }

            if let snapshot = snapshot,
               snapshot.exists,
               let data = snapshot.data(),
               let user = KeychyUser(id: uid, data: data) {
                // 프로필 로드 성공
                self.currentUser = user
                self.isLoaded = true
                self.saveToCache()

                // 필드 마이그레이션: 누락된 필드 자동 추가
                self.migrateUserFieldsIfNeeded(user: user)

                // 실시간 리스너 시작
                self.startUserListener(uid: uid)

                completion(true)
            } else {
                // 신규 유저 또는 프로필 미완성
                completion(false)
            }
        }
    }

    // MARK: - 실시간 리스너
    /// Firestore 유저 데이터 실시간 리스너 시작
    private func startUserListener(uid: String) {
        // 기존 리스너 제거
        userListener?.remove()

        userListener = db.collection("User").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if error != nil {
                return
            }

            guard let snapshot = snapshot,
                  snapshot.exists,
                  let data = snapshot.data(),
                  let user = KeychyUser(id: uid, data: data) else {
                return
            }

            // 유저 데이터 업데이트
            self.currentUser = user
            self.saveToCache()
        }
    }

    /// 실시간 리스너 중지
    func stopUserListener() {
        userListener?.remove()
        userListener = nil
    }

    // MARK: - UserDefaults 캐시 관리
    func saveToCache() {
        guard let user = currentUser else { return }

        UserDefaults.standard.set(user.id, forKey: "userUID")
        UserDefaults.standard.set(user.nickname, forKey: "userNickname")
        UserDefaults.standard.set(user.email, forKey: "userEmail")
        UserDefaults.standard.set(user.marketingAgreed, forKey: "userMarketingAgreed")
    }

    private func loadFromCache() {
        let uid = UserDefaults.standard.string(forKey: "userUID") ?? ""
        let nickname = UserDefaults.standard.string(forKey: "userNickname") ?? ""
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let marketingAgreed = UserDefaults.standard.bool(forKey: "userMarketingAgreed")

        if !uid.isEmpty {
            // 캐시에서 임시 유저 생성 (전체 데이터는 Firestore에서 로드 필요)
            var user = KeychyUser(
                id: uid,
                nickname: nickname,
                email: email
            )
            user.marketingAgreed = marketingAgreed
            currentUser = user
            isLoaded = true
        }
    }

    // MARK: - 필드 마이그레이션
    private func migrateUserFieldsIfNeeded(user: KeychyUser) {
        // merge: true로 누락된 필드만 추가 (기존 데이터는 유지)
        let userData = user.toDictionary()
        db.collection("User").document(user.id).setData(userData, merge: true) { error in
            // 필드 마이그레이션 처리
        }
    }

    // MARK: - 로그아웃
    /// Firebase Auth 로그아웃
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            clearUserInfo()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func clearUserInfo() {
        stopUserListener()
        currentUser = nil
        isLoaded = false

        // UserDefaults 삭제
        UserDefaults.standard.removeObject(forKey: "userNickname")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userUID")
        UserDefaults.standard.removeObject(forKey: "userMarketingAgreed")

        // 키링 캐시 전체 삭제
        KeyringImageCache.shared.clearAll()
    }

    // MARK: - 회원탈퇴
    /// Firebase Auth 계정 삭제 (재인증 필요 여부 확인)
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인된 사용자가 없음"])))
            return
        }

        let uid = user.uid

        // 1. 먼저 Firebase Auth 계정 삭제 시도 (재인증 필요 여부 확인)
        user.delete { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
            } else {
                // 2. Auth 삭제 성공 → Firestore 데이터 삭제
                self.deleteUserData(uid: uid) { result in
                    switch result {
                    case .success:
                        completion(.success(()))

                    case .failure:
                        // Auth는 이미 삭제됐지만 Firestore는 남아있음
                        // 어차피 로그인 불가능하므로 성공으로 처리
                        completion(.success(()))
                    }
                }
            }
        }
    }

    /// 재인증 후 회원탈퇴 진행
    func deleteAccountAfterReauth(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인된 사용자가 없음"])))
            return
        }

        let uid = user.uid

        // 1. Firebase Auth 계정 삭제
        user.delete { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
            } else {
                // 2. Auth 삭제 성공 → Firestore 데이터 삭제
                self.deleteUserData(uid: uid) { result in
                    switch result {
                    case .success:
                        completion(.success(()))

                    case .failure:
                        completion(.success(()))
                    }
                }
            }
        }
    }

    // MARK: - Firestore 데이터 삭제
    func deleteUserData(uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 1. User 문서에서 keyrings 배열 가져오기
        db.collection("User").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(.failure(NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserManager instance is nil"])))
                return
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(),
                  let keyringIds = data["keyrings"] as? [String] else {
                // keyrings가 없어도 User 문서는 삭제해야 하므로 계속 진행
                self.deleteUserDocument(uid: uid, completion: completion)
                return
            }

            // 2. Keyring 컬렉션에서 각 키링 문서 삭제
            let group = DispatchGroup()
            var deletionError: Error?

            for keyringId in keyringIds {
                group.enter()
                self.db.collection("Keyring").document(keyringId).delete { error in
                    if let error = error {
                        deletionError = error
                    }
                    group.leave()
                }
            }

            // 3. Storage에서 사용자 폴더 삭제 (BodyImages, CustomSounds)
            group.enter()
            Task {
                do {
                    try await StorageManager.shared.deleteUserFolder(uid: uid)
                    print("Storage 삭제 완료: \(uid)")
                } catch {
                    print("Storage 삭제 실패: \(error.localizedDescription)")
                    deletionError = error
                }
                group.leave()
            }

            // 4. 모든 삭제 완료 후 User 문서 삭제
            group.notify(queue: .main) {
                if let error = deletionError {
                    completion(.failure(error))
                } else {
                    self.deleteUserDocument(uid: uid, completion: completion)
                }
            }
        }
    }

    // User 문서 삭제 헬퍼 함수
    private func deleteUserDocument(uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("User").document(uid).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // 로컬 데이터 정리
                self.clearUserInfo()
                completion(.success(()))
            }
        }
    }

    // MARK: - Apple Sign In 재인증
    /// Apple Sign In 재인증 시작
    func startReauthentication(onSuccess: @escaping (AuthCredential) -> Void, onFailure: @escaping (Error) -> Void) {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        // Coordinator 생성 및 저장
        let coordinator = AppleAuthCoordinator(
            nonce: nonce,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
        authCoordinator = coordinator

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.performRequests()
    }

    /// Firebase 재인증
    func reauthenticateWithCredential(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "UserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인된 사용자 없음"])))
            return
        }

        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Helper Functions
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
    
    // MARK: - 코인 업데이트
    /// 유저의 코인을 증가시키고 Firestore에 저장
    func updateCoin(by amount: Int, completion: @escaping (Bool) -> Void) {
        guard var user = currentUser else {
            print("현재 유저가 없습니다.")
            completion(false)
            return
        }

        // 로컬 상태 업데이트
        user.coin += amount

        // Firestore에 업데이트
        db.collection("User").document(user.id).updateData([
            "coin": user.coin
        ]) { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }

            if let error = error {
                print("코인 업데이트 실패: \(error)")
                completion(false)
            } else {
                // 로컬 상태 반영
                self.currentUser = user
                print("코인 업데이트 성공: \(user.coin)")
                completion(true)
            }
        }
    }

}

// MARK: - AppleAuthCoordinator
class AppleAuthCoordinator: NSObject, ASAuthorizationControllerDelegate {
    private let nonce: String
    private let onSuccess: (AuthCredential) -> Void
    private let onFailure: (Error) -> Void

    init(nonce: String, onSuccess: @escaping (AuthCredential) -> Void, onFailure: @escaping (Error) -> Void) {
        self.nonce = nonce
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        onSuccess(credential)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onFailure(error)
    }
}
