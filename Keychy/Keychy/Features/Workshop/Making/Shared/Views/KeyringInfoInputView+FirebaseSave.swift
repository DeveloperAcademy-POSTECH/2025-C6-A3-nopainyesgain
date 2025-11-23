//
//  KeyringInfoInputView+FirebaseSave.swift
//  Keychy
//
//  Firebase 저장 로직
//

import SwiftUI
import FirebaseFirestore
import SpriteKit

extension KeyringInfoInputView {
    // MARK: - Firebase 저장 메인 함수
    func saveKeyringToFirebase() {
        guard let uid = userManager.currentUser?.id,
              let bodyImage = viewModel.bodyImage else {
            print("[KeyringSave] 저장 실패 - uid: \(userManager.currentUser?.id ?? "nil"), bodyImage: \(viewModel.bodyImage != nil)")
            isSavingToFirebase = false
            return
        }

        isSavingToFirebase = true

        // 1. Firebase Storage에 이미지 업로드
        uploadImageToStorage(image: bodyImage, uid: uid) { imageURL in
            guard let imageURL = imageURL else {
                self.isSavingToFirebase = false
                return
            }

            // 2. 커스텀 사운드가 있으면 Firebase Storage에 업로드
            if let customSoundURL = self.viewModel.customSoundURL {
                self.uploadSoundToStorage(soundURL: customSoundURL, uid: uid) { soundURL in
                    guard let soundURL = soundURL else {
                        // 업로드 실패 시 기존 soundId 사용
                        self.createKeyringWithData(uid: uid, imageURL: imageURL, soundId: self.viewModel.soundId)
                        return
                    }

                    // 업로드 성공 - Firebase Storage URL을 soundId로 사용
                    self.createKeyringWithData(uid: uid, imageURL: imageURL, soundId: soundURL)
                }
            } else {
                // 커스텀 사운드 없음 - 기존 soundId 사용
                self.createKeyringWithData(uid: uid, imageURL: imageURL, soundId: self.viewModel.soundId)
            }
        }
    }

    // MARK: - 키링 생성 헬퍼 메서드
    private func createKeyringWithData(uid: String, imageURL: String, soundId: String) {
        // hookOffsetY는 0이 아니면 사용, 0이면 nil로 전달
        let hookOffsetY: CGFloat? = viewModel.hookOffsetY != 0 ? viewModel.hookOffsetY : nil
        let templateId = viewModel.templateId

        self.createKeyring(
            uid: uid,
            name: self.viewModel.nameText,
            bodyImage: imageURL,
            soundId: soundId,
            particleId: self.viewModel.particleId,
            memo: self.viewModel.memoText.isEmpty ? nil : self.viewModel.memoText,
            tags: self.viewModel.selectedTags,
            selectedTemplate: templateId,
            selectedRing: "basic",
            selectedChain: "basic",
            chainLength: self.viewModel.chainLength,
            isNew: true,
            hookOffsetY: hookOffsetY
        ) { success, keyringId in
            // 백그라운드로 위젯용 이미지 캡처 및 저장
            if success, let keyringId = keyringId {
                // viewModel이 reset되기 전에 이름과 hookOffsetY, chainLength를 미리 캡처
                let keyringName = self.viewModel.nameText
                let chainLength = self.viewModel.chainLength

                // 최근 사용 템플릿에 추가
                self.addTemplateToRecentlyUsed(uid: uid, templateId: templateId)

                Task {
                    // 위젯 캐싱 완료 대기
                    await self.captureAndCacheKeyring(
                        keyringId: keyringId,
                        keyringName: keyringName,
                        bodyImage: imageURL,
                        templateId: templateId,
                        ringType: .basic,
                        chainType: .basic,
                        hookOffsetY: hookOffsetY,
                        chainLength: chainLength
                    )

                    // 모든 작업 완료 후 CompleteView로 이동
                    await MainActor.run {
                        self.isSavingToFirebase = false
                        self.router.push(self.nextRoute)
                        self.viewModel.createdAt = Date()
                    }
                }
            } else {
                // 실패 시 로딩 종료
                self.isSavingToFirebase = false
            }
        }
    }

    // MARK: - Firebase Storage에 이미지 업로드
    private func uploadImageToStorage(image: UIImage, uid: String, completion: @escaping (String?) -> Void) {
        let fileName = "\(UUID().uuidString).png"
        let path = "Keyrings/BodyImages/\(uid)/\(fileName)"

        Task {
            do {
                let downloadURL = try await StorageManager.shared.uploadImage(image, path: path)
                completion(downloadURL)
            } catch {
                print("이미지 업로드 실패: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    // MARK: - Firebase Storage에 커스텀 사운드 업로드
    private func uploadSoundToStorage(soundURL: URL, uid: String, completion: @escaping (String?) -> Void) {
        guard let soundData = try? Data(contentsOf: soundURL) else {
            completion(nil)
            return
        }

        let fileName = "\(UUID().uuidString).m4a"
        let path = "Keyrings/CustomSounds/\(uid)/\(fileName)"

        Task {
            do {
                let downloadURL = try await StorageManager.shared.uploadAudio(soundData, path: path)
                completion(downloadURL)
            } catch {
                print("커스텀 사운드 업로드 실패: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    // MARK: - 새 키링 생성 및 User에 추가
    func createKeyring(
        uid: String,
        name: String,
        bodyImage: String,
        soundId: String,
        particleId: String,
        memo: String?,
        tags: [String],
        selectedTemplate: String,
        selectedRing: String,
        selectedChain: String,
        chainLength: Int,
        isNew: Bool,
        hookOffsetY: CGFloat? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let newKeyring = Keyring(
            name: name,
            bodyImage: bodyImage,
            soundId: soundId,
            particleId: particleId,
            memo: memo,
            tags: tags,
            createdAt: Date(),
            authorId: uid,
            selectedTemplate: selectedTemplate,
            selectedRing: selectedRing,
            selectedChain: selectedChain,
            chainLength: chainLength,
            isNew: isNew,
            hookOffsetY: hookOffsetY
        )

        let keyringData = newKeyring.toDictionary()

        // Keyring 컬렉션에 새 키링 추가
        let docRef = db.collection("Keyring").document()

        docRef.setData(keyringData) { error in
            if let error = error {
                print("[KeyringSave] Firestore 저장 에러: \(error.localizedDescription)")
                completion(false, nil)
                return
            }

            let keyringId = docRef.documentID

            // User 문서의 keyrings 배열에 ID 추가
            self.addKeyringToUser(uid: uid, keyringId: keyringId) { success in
                if success {
                    completion(true, keyringId)
                } else {
                    completion(false, nil)
                }
            }
        }
    }

    // MARK: - User의 keyrings 배열에 키링 ID 추가
    private func addKeyringToUser(uid: String, keyringId: String, completion: @escaping (Bool) -> Void) {
        db.collection("User")
            .document(uid)
            .updateData([
                "keyrings": FieldValue.arrayUnion([keyringId])
            ]) { error in
                if let error = error {
                    print("[KeyringSave] User 키링 배열 업데이트 에러: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("[KeyringSave] 키링 저장 완료!")
                    completion(true)
                }
            }
    }

    // MARK: - User의 최근 사용 템플릿에 추가
    private func addTemplateToRecentlyUsed(uid: String, templateId: String) {
        db.collection("User")
            .document(uid)
            .updateData([
                "currentUsedTemplates": FieldValue.arrayUnion([templateId])
            ])
    }

    // MARK: - 위젯용 이미지 캡처 및 캐싱
    private func captureAndCacheKeyring(
        keyringId: String,
        keyringName: String,
        bodyImage: String,
        templateId: String?,
        ringType: RingType,
        chainType: ChainType,
        hookOffsetY: CGFloat?,
        chainLength: Int
    ) async {
        await withCheckedContinuation { continuation in
            // 이미지 로딩 완료 콜백
            var loadingCompleted = false

            // Scene 생성 (onLoadingComplete 콜백 추가, 투명 배경)
            let scene = KeyringCellScene(
                ringType: ringType,
                chainType: chainType,
                bodyImage: bodyImage,
                templateId: templateId,
                targetSize: CGSize(width: 175, height: 233),
                customBackgroundColor: .clear,
                zoomScale: 2.0,
                hookOffsetY: hookOffsetY,
                chainLength: chainLength,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.scaleMode = .aspectFill

            // SKView 생성 및 Scene 표시 (렌더링 시작)
            let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
            view.allowsTransparency = true
            view.presentScene(scene)

            // 로딩 완료 대기 (최대 3초)
            Task {
                var waitTime = 0.0
                let checkInterval = 0.1 // 100ms마다 체크
                let maxWaitTime = 3.0   // 최대 3초

                while !loadingCompleted && waitTime < maxWaitTime {
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                    waitTime += checkInterval
                }

                if !loadingCompleted {
                    print("[InfoInput] 타임아웃 - 로딩 미완료: \(keyringId)")
                } else {
                    // 로딩 완료 후 추가 렌더링 대기 (200ms)
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // PNG 캡처
                if let pngData = await scene.captureToPNG() {
                    // FileManager 캐시에 저장 (위젯에서 접근 가능)
                    KeyringImageCache.shared.save(pngData: pngData, for: keyringId)

                    // App Group에 위젯용 이미지 및 메타데이터 동기화
                    KeyringImageCache.shared.syncKeyring(
                        id: keyringId,
                        name: keyringName,
                        imageData: pngData
                    )

                } else {
                    print("[InfoInput] 캡처 실패: \(keyringId)")
                }

                continuation.resume()
            }
        }
    }
}
