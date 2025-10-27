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
    
    var userNickname: String = ""
    var userEmail: String = ""
    var userUID: String = ""
    var isLoaded: Bool = false
    
    private let db = Firestore.firestore()
    
    private init() {
        loadFromCache()
    }
    
    // MARK: - 프로필 로드 (Firestore → 로컬)
    func loadUserInfo(uid: String, completion: @escaping (Bool) -> Void) {
        db.collection("User").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Firestore 로드 에러: \(error)")
                self.loadFromAuth(uid: uid)
                completion(false)
                return
            }
            
            if let data = snapshot?.data(),
               let nickname = data["nickname"] as? String,
               !nickname.isEmpty {
                // 프로필 완성
                self.userUID = uid
                self.userNickname = nickname
                self.userEmail = data["email"] as? String ?? Auth.auth().currentUser?.email ?? ""
                self.isLoaded = true
                self.saveToCache()
                
                print("프로필 로드 완료: \(nickname)")
                completion(true)
            } else {
                // 닉네임 없음
                print("프로필 미완성")
                completion(false)
            }
        }
    }
    
    // MARK: - 프로필 저장 (로컬 + Firestore)
    func saveProfile(uid: String, nickname: String, email: String, completion: @escaping (Bool) -> Void) {
        let userData: [String: Any] = [
            "nickname": nickname,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
        ]
        
        db.collection("User").document(uid).setData(userData, merge: true) { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Firestore 저장 실패: \(error)")
                completion(false)
            } else {
                // 저장 성공 시 로컬 상태도 업데이트
                self.userUID = uid
                self.userNickname = nickname
                self.userEmail = email
                self.isLoaded = true
                self.saveToCache()
                
                // Auth에도 displayName 저장
                if let user = Auth.auth().currentUser {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = nickname
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("displayName 저장 실패: \(error)")
                        }
                    }
                }
                
                print("프로필 저장 완료")
                completion(true)
            }
        }
    }
    
    private func loadFromAuth(uid: String) {
        guard let user = Auth.auth().currentUser else { return }
        userUID = uid
        userNickname = user.displayName ?? "사용자"
        userEmail = user.email ?? ""
        isLoaded = true
        saveToCache()
    }
    
    // MARK: - UserDefaults 캐시
    func saveToCache() {
        UserDefaults.standard.set(userNickname, forKey: "userNickname")
        UserDefaults.standard.set(userEmail, forKey: "userEmail")
        UserDefaults.standard.set(userUID, forKey: "userUID")
    }
    
    private func loadFromCache() {
        userNickname = UserDefaults.standard.string(forKey: "userNickname") ?? ""
        userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        userUID = UserDefaults.standard.string(forKey: "userUID") ?? ""
        
        if !userUID.isEmpty {
            isLoaded = true
        }
    }
    
    func clearUserInfo() {
        userNickname = ""
        userEmail = ""
        userUID = ""
        isLoaded = false
        
        UserDefaults.standard.removeObject(forKey: "userNickname")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userUID")
    }
    
}
