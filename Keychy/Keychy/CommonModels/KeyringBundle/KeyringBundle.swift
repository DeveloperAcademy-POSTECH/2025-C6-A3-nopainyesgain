//
//  KeyringBundle.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct KeyringBundle: Identifiable, Equatable, Hashable {
    let id = UUID()
    
    var userId: String
    var name: String
    var selectedBackground: String
    var selectedCarabiner: String
    var keyrings: [String]
    var maxKeyrings: Int
    var isMain: Bool
    var createdAt: Date
    
    //MARK: - Firestore 변환
    func toDictionary() -> [String: Any] {
        let dict: [String: Any] = [
            "userId": userId,
            "name": name,
            "selectedBackground": selectedBackground,
            "selectedCarabiner": selectedCarabiner,
            "keyrings": keyrings,
            "maxKeyrings": maxKeyrings,
            "isMain": isMain,
            "createdAt": Timestamp(date: createdAt)
        ]
        return dict
    }
    
    //MARK: - Firestore DocumentSnapshot에서 초기화
    init?(documentId: String, data: [String: Any]) {
        guard let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let selectedBackground = data["selectedBackground"] as? String,
              let selectedCarabiner = data["selectedCarabiner"] as? String,
              let keyrings = data["keyrings"] as? [String],
              let maxKeyrings = data["maxKeyrings"] as? Int,
              let isMain = data["isMain"] as? Bool,
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        self.userId = userId
        self.name = name
        self.selectedBackground = selectedBackground
        self.selectedCarabiner = selectedCarabiner
        self.keyrings = keyrings
        self.maxKeyrings = maxKeyrings
        self.isMain = isMain
        self.createdAt = createdAtTimestamp.dateValue()
    }
    
    //MARK: - 일반 초기화 (새 번들 생성용)
    init(userId: String,
         name: String,
         selectedBackground: String,
         selectedCarabiner: String,
         keyrings: [String],
         maxKeyrings: Int,
         isMain: Bool,
         createdAt: Date
    ) {
        self.userId = userId
        self.name = name
        self.selectedBackground = selectedBackground
        self.selectedCarabiner = selectedCarabiner
        self.keyrings = keyrings
        self.maxKeyrings = maxKeyrings
        self.isMain = isMain
        self.createdAt = createdAt
    }
}
