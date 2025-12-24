//
//  IntroViewModel+Bundle.swift
//  Keychy
//
//  Created by 길지훈 on 11/14/25.
//

import SwiftUI
import SpriteKit
import FirebaseFirestore

extension IntroViewModel {
    // MARK: - 웰컴키링으로 번들 생성
    func makeBundle(welcomeKeyringId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = UserManager.shared.currentUser?.id else {
            print("사용자 ID를 모르겠람쥐")
            completion(false, nil)
            return
        }

        let db = Firestore.firestore()

        // Welcome 카라비너 정보 가져오기
        db.collection("Carabiner").document("WelcomeKeychy").getDocument { snapshot, error in
            if let error = error {
                print("카라비너 로드 에러: \(error.localizedDescription)")
                completion(false, nil)
                return
            }

            guard let data = snapshot?.data(),
                  let maxKeyrings = data["maxKeyringCount"] as? Int else {
                print("카라비너 데이터 파싱 실패")
                completion(false, nil)
                return
            }

            // keyrings 배열 생성 (첫 번째 슬롯에 웰컴키링, 나머지는 "none")
            var keyrings = Array(repeating: "none", count: maxKeyrings)
            keyrings[1] = welcomeKeyringId

            // CollectionViewModel 사용해서 번들 생성
            let collectionVM = CollectionViewModel()
            collectionVM.createBundle(
                userId: userId,
                name: "웰컴뭉치",
                selectedBackground: "PurpleKeychy",
                selectedCarabiner: "WelcomeKeychy",
                keyrings: keyrings,
                maxKeyrings: maxKeyrings,
                isMain: true
            ) { [collectionVM] success, bundleId in
                _ = collectionVM  // 비동기 작업 끝날 때까지 유지
                completion(success, bundleId)
            }
        }
    }
}
