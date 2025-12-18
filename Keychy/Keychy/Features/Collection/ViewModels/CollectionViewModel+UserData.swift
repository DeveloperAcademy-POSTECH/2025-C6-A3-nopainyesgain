//
//  CollectionViewModel+UserData.swift
//  Keychy
//
//  Created by Jini on 12/18/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: -  사용자 정보 로드 및 조회 (닉네임, 재화 등)
extension CollectionViewModel {
    
    // 사용자 닉네임 조회
    func fetchUserNickname(userId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("User")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("사용자 정보 조회 실패: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let nickname = data["nickname"] as? String else {
                    completion(nil)
                    return
                }
                
                completion(nickname)
            }
    }
}
