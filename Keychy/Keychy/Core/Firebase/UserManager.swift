//
//  UserManager.swift
//  Keychy
//
//  Created by Jini on 10/28/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@Observable
class UserManager {
    static let shared = UserManager()

    /// 유저 모델
    var currentUser: KeychyUser?

    var isLoaded: Bool = false

    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?

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

            if let error = error {
                print("Firestore 저장 실패: \(error)")
                completion(false)
            } else {
                // 저장 성공 시 로컬 상태 업데이트
                self.currentUser = user
                self.isLoaded = true
                self.saveToCache()
                print("프로필 저장 완료")
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

            if let error = error {
                print("Firestore 로드 에러: \(error)")
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

                print("프로필 로드 완료: \(user.nickname)")
                completion(true)
            } else {
                // 신규 유저 또는 프로필 미완성
                print("프로필 미완성 - 회원가입 필요")
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

            if let error = error {
                print("실시간 리스너 에러: \(error)")
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
            print("실시간 업데이트: \(user.nickname)")
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
    }

    private func loadFromCache() {
        let uid = UserDefaults.standard.string(forKey: "userUID") ?? ""
        let nickname = UserDefaults.standard.string(forKey: "userNickname") ?? ""
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""

        if !uid.isEmpty {
            // 캐시에서 임시 유저 생성 (전체 데이터는 Firestore에서 로드 필요)
            currentUser = KeychyUser(
                id: uid,
                nickname: nickname,
                email: email
            )
            isLoaded = true
        }
    }

    // MARK: - 필드 마이그레이션
    private func migrateUserFieldsIfNeeded(user: KeychyUser) {
        // merge: true로 누락된 필드만 추가 (기존 데이터는 유지)
        let userData = user.toDictionary()
        db.collection("User").document(user.id).setData(userData, merge: true) { error in
            if let error = error {
                print("필드 마이그레이션 실패: \(error)")
            } else {
                print("필드 마이그레이션 완료")
            }
        }
    }

    func clearUserInfo() {
        stopUserListener()
        currentUser = nil
        isLoaded = false

        UserDefaults.standard.removeObject(forKey: "userNickname")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userUID")
    }

}
