//
//  KeychyUser.swift
//  Keychy
//
//  Created by Jini on 10/27/25.
//

import SwiftUI
import FirebaseFirestore

struct KeychyUser: Identifiable {

    // Firebase Auth UID (Firestore 문서 ID와 동일)
    var id: String
    var nickname: String
    var email: String
    var createdAt: Date
    var maxKeyringCount: Int = 100
    var coin: Int
    var copyVoucher: Int
    var templates: [String]
    var rings: [String]
    var chains: [String]
    var soundEffects: [String]
    var particleEffects: [String]
    var backgrounds: [String]
    var carabiners: [String]
    var tags: [String]
    var keyrings: [String]
    var termsAgreed: Bool         // 필수 약관 동의 여부
    var marketingAgreed: Bool     // 마케팅 수신 동의 여부

    // MARK: - Firestore 변환
    func toDictionary() -> [String: Any] {
        return [
            "nickname": nickname,
            "email": email,
            "createdAt": Timestamp(date: createdAt),
            "maxKeyringCount": maxKeyringCount,
            "coin": coin,
            "copyVoucher": copyVoucher,
            "templates": templates,
            "rings": rings,
            "chains": chains,
            "soundEffects": soundEffects,
            "particleEffects": particleEffects,
            "backgrounds": backgrounds,
            "carabiners": carabiners,
            "tags": tags,
            "keyrings": keyrings,
            "termsAgreed": termsAgreed,
            "marketingAgreed": marketingAgreed
        ]
    }

    // Firestore DocumentSnapshot에서 초기화
    init?(id: String, data: [String: Any]) {
        guard let nickname = data["nickname"] as? String,
              let email = data["email"] as? String,
              let timestamp = data["createdAt"] as? Timestamp else {
            return nil
        }

        self.id = id
        self.nickname = nickname
        self.email = email
        self.createdAt = timestamp.dateValue()
        self.maxKeyringCount = data["maxKeyringCount"] as? Int ?? 50
        self.coin = data["coin"] as? Int ?? 0
        self.copyVoucher = data["copyVoucher"] as? Int ?? 0
        self.templates = data["templates"] as? [String] ?? []
        self.rings = data["rings"] as? [String] ?? []
        self.chains = data["chains"] as? [String] ?? []
        self.soundEffects = data["soundEffects"] as? [String] ?? []
        self.particleEffects = data["particleEffects"] as? [String] ?? []
        self.backgrounds = data["backgrounds"] as? [String] ?? []
        self.carabiners = data["carabiners"] as? [String] ?? []
        self.tags = data["tags"] as? [String] ?? []
        self.keyrings = data["keyrings"] as? [String] ?? []
        self.termsAgreed = data["termsAgreed"] as? Bool ?? false
        self.marketingAgreed = data["marketingAgreed"] as? Bool ?? false
    }

    // 일반 초기화 (새 유저 생성용)
    init(id: String, nickname: String, email: String) {
        self.id = id
        self.nickname = nickname
        self.email = email
        self.createdAt = Date()
        self.maxKeyringCount = 100
        self.coin = 0
        self.copyVoucher = 5
        self.templates = []
        self.rings = []
        self.chains = []
        self.soundEffects = []
        self.particleEffects = []
        self.backgrounds = []
        self.carabiners = []
        self.tags = []
        self.keyrings = []
        self.termsAgreed = false
        self.marketingAgreed = false
    }
}
