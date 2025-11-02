//
//  KeyringCompleteView.swift
//  KeytschPrototype
//
//  키링 완성 화면
//  - 모든 템플릿에서 공통으로 사용 가능
//

import SwiftUI
import SpriteKit
import FirebaseFirestore
import FirebaseStorage

struct KeyringCompleteView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: VM
    let navigationTitle: String

    var userManager: UserManager = UserManager.shared

    // Firebase
    let db = Firestore.firestore()
    @State private var keyring: [Keyring] = []
    @State private var isCreatingKeyring: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("completeBG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 타이틀
                    Spacer()

                    // 키링 씬
                    keyringScene

                    Spacer()

                    // 키링 정보
                    keyringInfo
                        .padding(.bottom, 30)

                    // 이미지 저장 버튼
                    saveButton
                        .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .toolbar {
            backToolbarItem
        }
        .navigationTitle("키링이 완성되었어요!")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !isCreatingKeyring else { return }
            isCreatingKeyring = true
            saveKeyringToFirebase()
        }
    }
}

// MARK: - KeyringScene Section
extension KeyringCompleteView {
    private var keyringScene: some View {
        KeyringSceneView(viewModel: viewModel, backgroundColor: .clear)
            .frame(maxWidth: .infinity)
            .frame(height: 500)
            .scaleEffect(1.2)
    }
}

//MARK: - 툴바
extension KeyringCompleteView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                router.reset()
            }) {
                Image(systemName: "xmark")
            }
        }
    }
}

// MARK: - 키링 정보 뷰
extension KeyringCompleteView {
    private var keyringInfo: some View {
        VStack(spacing: 8) {
            Text(viewModel.nameText)
                .typography(.suit20B)
                .foregroundStyle(.black100)

            Text(formattedDate(date: viewModel.createdAt))
                .typography(.suit14M)
                .foregroundStyle(.gray300)

            if let nickname = userManager.currentUser?.nickname {
                Text("@\(nickname)")
                    .typography(.suit16M)
                    .foregroundStyle(.black100)
            }
        }
    }

    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
}

// MARK: - 저장 버튼
extension KeyringCompleteView {
    private var saveButton: some View {
        VStack(spacing: 12) {
            Button {
                // 이미지 저장 로직
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(.black100)

                    Text("이미지 저장")
                        .typography(.suit14M)
                        .foregroundStyle(.black100)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.8))
                )
            }
        }
    }
}

extension KeyringCompleteView {
    // MARK: - Firebase 저장 메인 함수
    private func saveKeyringToFirebase() {
        guard let uid = userManager.currentUser?.id,
              let bodyImage = viewModel.bodyImage else {
            return
        }

        // 1. Firebase Storage에 이미지 업로드
        uploadImageToStorage(image: bodyImage, uid: uid) { imageURL in
            guard let imageURL = imageURL else {
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
        let templateId: String
        if let vm = self.viewModel as? AcrylicPhotoVM {
            templateId = vm.template?.id ?? "AcrylicPhoto"
        } else {
            templateId = "AcrylicPhoto"
        }

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
            chainLength: 5
        ) { success, keyringId in
            // 키링 생성 완료
        }
    }

    // MARK: - Firebase Storage에 이미지 업로드
    private func uploadImageToStorage(image: UIImage, uid: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.pngData() else {
            completion(nil)
            return
        }

        let fileName = "\(UUID().uuidString).png"
        let storageRef = Storage.storage().reference()
            .child("Keyrings")
            .child("BodyImages")
            .child(uid)
            .child(fileName)

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if error != nil {
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if error != nil {
                    completion(nil)
                    return
                }

                completion(url?.absoluteString)
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
        let storageRef = Storage.storage().reference()
            .child("Keyrings")
            .child("CustomSounds")
            .child(uid)
            .child(fileName)

        storageRef.putData(soundData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading custom sound: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                completion(url?.absoluteString)
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
            chainLength: chainLength
        )
        
        let keyringData = newKeyring.toDictionary()
        
        // Keyring 컬렉션에 새 키링 추가
        let docRef = db.collection("Keyring").document()
        
        docRef.setData(keyringData) { error in
            if let error = error {
                completion(false, nil)
                return
            }

            let keyringId = docRef.documentID

            // User 문서의 keyrings 배열에 ID 추가
            self.addKeyringToUser(uid: uid, keyringId: keyringId) { success in
                if success {
                    // 로컬 배열에도 추가
                    let mutableKeyring = newKeyring
                    self.keyring.append(mutableKeyring)

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
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }
}
