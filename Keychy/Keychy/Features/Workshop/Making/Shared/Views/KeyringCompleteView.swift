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
    @State var keyring: [Keyring] = []
    @State var isCreatingKeyring: Bool = false
    
    // 시네마틱 애니메이션
    @State var showDismissButton = false
    
    // 이미지 저장
    @State var checkmarkScale: CGFloat = 0.3
    @State var checkmarkOpacity: Double = 0.0
    @State var showImageSaved = false
    @State var showSaveButton = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("completeBG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .cinematicAppear(delay: 0, duration: 0.6, style: .fadeIn)
                
                VStack(spacing: 0) {
                    // 키링 씬
                    keyringScene
                        .cinematicAppear(delay: 0.2, duration: 0.8, style: .full)
                    
                    // 키링 정보
                    keyringInfo
                        .padding(.bottom, 30)
                        .cinematicAppear(delay: 0.6, duration: 0.8, style: .slideUp)

                    // 이미지 저장 버튼 (공간 유지를 위해 opacity 사용)
                    saveButton
                        .cinematicAppear(delay: 0.8, duration: 0.8, style: .slideUp)
                        .padding(.top, 30)
                        .opacity(showSaveButton ? 1 : 0)
                }
                
                if showImageSaved {
                    ImageSaveAlert(checkmarkScale: checkmarkScale)
                        .padding(.bottom, 30)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backToolbarItem
        }
        .navigationTitle(showDismissButton ? "키링이 완성되었어요!" : "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !isCreatingKeyring else { return }
            isCreatingKeyring = true

            // Firebase 저장 시작 (completion으로 dismiss 버튼 표시)
            saveKeyringToFirebase {
                DispatchQueue.main.async {
                    showDismissButton = true
                    showSaveButton = true
                }
            }
        }
    }
}

// MARK: - KeyringScene Section
extension KeyringCompleteView {
    private var keyringScene: some View {
        KeyringSceneView(viewModel: viewModel, backgroundColor: .clear)
            .frame(maxWidth: .infinity)
            .frame(height: 500)
    }
}

//MARK: - 툴바
extension KeyringCompleteView {
    @ToolbarContentBuilder
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if showDismissButton {
                Button(action: {
                    viewModel.resetAll()
                    router.reset()
                }) {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

// MARK: - 키링 정보 뷰
extension KeyringCompleteView {
    private var keyringInfo: some View {
        VStack(spacing: 0) {
            Text(viewModel.nameText)
                .typography(.notosans24M)
                .foregroundStyle(.black100)
            
            Text(formattedDate(date: viewModel.createdAt))
                .typography(.suit14M)
                .foregroundStyle(.black100)
                .padding(.bottom, 15)
            
            if let nickname = userManager.currentUser?.nickname {
                Text("@\(nickname)")
                    .typography(.notosans15M)
                    .foregroundStyle(.black100)
                    .padding(.vertical, 1)
            }
        }
    }
    
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
}

// MARK: - 저장 버튼
extension KeyringCompleteView {
    private var saveButton: some View {
        VStack(spacing: 9) {
            Button {
                captureAndSaveImage()
            } label: {
                Image("imageDownload")
            }
            .buttonStyle(.glass)
            
            Text("이미지 저장")
                .typography(.suit13SB)
                .foregroundStyle(.black100)
        }
    }
}

extension KeyringCompleteView {
    // MARK: - Firebase 저장 메인 함수
    private func saveKeyringToFirebase(completion: @escaping () -> Void) {
        guard let uid = userManager.currentUser?.id,
              let bodyImage = viewModel.bodyImage else {
            completion()
            return
        }

        // 1. Firebase Storage에 이미지 업로드
        uploadImageToStorage(image: bodyImage, uid: uid) { imageURL in
            guard let imageURL = imageURL else {
                completion()
                return
            }

            // 2. 커스텀 사운드가 있으면 Firebase Storage에 업로드
            if let customSoundURL = self.viewModel.customSoundURL {
                self.uploadSoundToStorage(soundURL: customSoundURL, uid: uid) { soundURL in
                    guard let soundURL = soundURL else {
                        // 업로드 실패 시 기존 soundId 사용
                        self.createKeyringWithData(uid: uid, imageURL: imageURL, soundId: self.viewModel.soundId, completion: completion)
                        return
                    }

                    // 업로드 성공 - Firebase Storage URL을 soundId로 사용
                    self.createKeyringWithData(uid: uid, imageURL: imageURL, soundId: soundURL, completion: completion)
                }
            } else {
                // 커스텀 사운드 없음 - 기존 soundId 사용
                self.createKeyringWithData(uid: uid, imageURL: imageURL, soundId: self.viewModel.soundId, completion: completion)
            }
        }
    }

    // MARK: - 키링 생성 헬퍼 메서드
    private func createKeyringWithData(uid: String, imageURL: String, soundId: String, completion: @escaping () -> Void) {
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
            // 백그라운드로 위젯용 이미지 캡처 및 저장
            if success, let keyringId = keyringId {
                // viewModel이 reset되기 전에 이름을 미리 캡처
                let keyringName = self.viewModel.nameText

                Task {
                    // 위젯 캐싱 완료 대기
                    await self.captureAndCacheKeyring(
                        keyringId: keyringId,
                        keyringName: keyringName,  // 캡처된 이름 전달
                        bodyImage: imageURL,
                        ringType: .basic,
                        chainType: .basic
                    )

                    // 모든 작업 완료 후 dismiss 버튼 표시
                    await MainActor.run {
                        completion()
                    }
                }
            } else {
                // 실패 시 바로 completion
                completion()
            }
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
            if error != nil {
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
                if error != nil {
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }

    // MARK: - 위젯용 이미지 캡처 및 캐싱
    private func captureAndCacheKeyring(
        keyringId: String,
        keyringName: String,  // 파라미터로 이름 받기
        bodyImage: String,
        ringType: RingType,
        chainType: ChainType
    ) async {
        await withCheckedContinuation { continuation in
            // 이미지 로딩 완료 콜백
            var loadingCompleted = false

            // Scene 생성 (onLoadingComplete 콜백 추가, 투명 배경)
            let scene = KeyringCellScene(
                ringType: ringType,
                chainType: chainType,
                bodyImage: bodyImage,
                targetSize: CGSize(width: 175, height: 233),
                customBackgroundColor: .clear,
                zoomScale: 2.0,
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
                    print("⚠️ [KeyringComplete] 타임아웃 - 로딩 미완료: \(keyringId)")
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
                    print("❌ [KeyringComplete] 캡처 실패: \(keyringId)")
                }

                continuation.resume()
            }
        }
    }
}
