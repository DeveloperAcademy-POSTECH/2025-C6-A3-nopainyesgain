//
//  IntroViewModel+WelcomeKeyring.swift
//  Keychy
//
//  Created by 길지훈 on 11/11/25.
//

import Foundation
import UIKit
import SpriteKit
import FirebaseFirestore

// MARK: - 환영 키링 생성
extension IntroViewModel {

    func createWelcomeKeyring(nickname: String, bodyImage: UIImage, uid: String) async throws -> String {
        let imageURL = try await uploadWelcomeImage(bodyImage, uid: uid)

        let keyringId = try await createKeyringDocument(
            uid: uid,
            name: nickname,
            bodyImageURL: imageURL
        )

        try await addKeyringToUser(uid: uid, keyringId: keyringId)

        // 웰컴 카라비너를 사용자의 carabiners 필드에 추가
        try await addWelcomeCarabinerToUser(uid: uid)

        Task.detached {
            await self.cacheWelcomeKeyring(
                keyringId: keyringId,
                nickname: nickname,
                imageURL: imageURL
            )
        }

        return keyringId
    }

    // MARK: - Storage 이미지 업로드
    private func uploadWelcomeImage(_ image: UIImage, uid: String) async throws -> String {
        let fileName = "\(UUID().uuidString).png"
        let path = "Keyrings/BodyImages/\(uid)/\(fileName)"

        return try await StorageManager.shared.uploadImage(image, path: path)
    }

    // MARK: - Firestore 키링 생성
    private func createKeyringDocument(uid: String, name: String, bodyImageURL: String) async throws -> String {
        let keyring = Keyring(
            name: name,
            bodyImage: bodyImageURL,
            soundId: "none",  // 사운드 없음
            particleId: "Confetti",
            memo: """
            ╭ ◜◝ ͡ ◜◝ ͡ ◜◝ ͡ ◜◝ ͡ ◜◝ ╮
             키치 앱 재밌게 사용해주세요♡
            ╰ ◟◞ ͜ ◟ ͜ ◟◞ ͜ ◟ ͜ ◟◞◟◞╯
            ⠀⠀⠀⠀O
            ⠀⠀⠀⠀⠀°
                   o　 ()＿()
            ‎  ⊂⌒ （   ^ ﻌ ^ ）
              ヽ_っ  ＿/￣￣￣/
            　 　  ＼/＿＿＿/    - 개발진 올림 -
            """,
            tags: [],
            createdAt: Date(),
            authorId: "KEYCHY",
            selectedTemplate: "welcome",
            selectedRing: "basicRing",
            selectedChain: "basicChain1",
            chainLength: 5,
            isEditable: false,
            hookOffsetY: 0.08
        )

        let docRef = Firestore.firestore().collection("Keyring").document()
        try await docRef.setData(keyring.toDictionary())

        return docRef.documentID
    }

    // MARK: - User keyrings 배열에 추가
    private func addKeyringToUser(uid: String, keyringId: String) async throws {
        try await Firestore.firestore()
            .collection("User")
            .document(uid)
            .updateData(["keyrings": FieldValue.arrayUnion([keyringId])])
    }

    // MARK: - User carabiners 배열에 웰컴 카라비너 추가
    private func addWelcomeCarabinerToUser(uid: String) async throws {
        try await Firestore.firestore()
            .collection("User")
            .document(uid)
            .updateData(["carabiners": FieldValue.arrayUnion(["WelcomeKeychy"])])
    }

    // MARK: - 위젯용 캐싱 (KeyringCompleteView 로직 재사용)
    private func cacheWelcomeKeyring(keyringId: String, nickname: String, imageURL: String) async {
        await withCheckedContinuation { continuation in
            var loadingCompleted = false

            // KeyringCellScene 생성 (위젯용 작은 크기)
            let scene = KeyringCellScene(
                ringType: .basic,
                chainType: .basic,
                bodyImage: imageURL,
                targetSize: CGSize(width: 175, height: 233),
                customBackgroundColor: .clear,
                zoomScale: 2.0,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.scaleMode = .aspectFill

            // SKView 생성 및 렌더링
            let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
            view.allowsTransparency = true
            view.presentScene(scene)

            // 로딩 완료 대기
            Task {
                var waitTime = 0.0
                let checkInterval = 0.1
                let maxWaitTime = 3.0

                while !loadingCompleted && waitTime < maxWaitTime {
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                    waitTime += checkInterval
                }

                if !loadingCompleted {
                    print("[WelcomeKeyring] 위젯 캐싱 타임아웃: \(keyringId)")
                } else {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // PNG 캡처 및 저장
                if let pngData = await scene.captureToPNG() {
                    KeyringImageCache.shared.save(pngData: pngData, for: keyringId)
                    KeyringImageCache.shared.syncKeyring(
                        id: keyringId,
                        name: nickname,
                        imageData: pngData
                    )
                    print("[WelcomeKeyring] 위젯 캐싱 완료: \(keyringId)")
                } else {
                    print("[WelcomeKeyring] 위젯 캐싱 실패: \(keyringId)")
                }

                continuation.resume()
            }
        }
    }
}
