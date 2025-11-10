//
//  BundleNameInputView.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SwiftUI
import SpriteKit

struct BundleNameInputView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    /// 번들 이름 입력용 State
    @State private var bundleName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    // 업로드 상태
    @State private var isUploading: Bool = false
    @State private var uploadError: String?
    
    // 선택된 키링들을 ViewModel에서 가져옴
    private var selectedKeyrings: [Int: Keyring] {
        viewModel.selectedKeyringsForBundle
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 20) {
                // 씬 표시 - ViewModel에 저장된 씬 재활용
                keyringSceneView(geo: geo)
                    .frame(height: geo.size.height * 0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 82)
                    .padding(.bottom, 20)
                
                // 번들 이름 입력 섹션
                bundleNameTextField()
                    .padding(.horizontal, 20)
                
                if isUploading {
                    ProgressView("업로드 중...")
                        .padding(.top, 8)
                }
                if let uploadError {
                    Text(uploadError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
                
                Spacer()
            }
            .padding(.bottom, max(380 - keyboardHeight, 20))
            .onAppear {
                // 키보드 자동 활성화
                DispatchQueue.main.async {
                    isTextFieldFocused = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
        // 키보드 올라옴 내려옴을 감지하는 notification center, 개발록 '키보드가 올라오면서 화면을 가릴 때'에서 소개한 내용과 같습니다.
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - 카라비너 + 키링 SpriteKit 씬 표시 (ViewModel에서 재활용)
extension BundleNameInputView {
    private func keyringSceneView(geo: GeometryProxy) -> some View {
        ZStack {
            if let scene = viewModel.bundlePreviewScene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .background(.clear)
                    .onAppear {
                        // 씬을 미리보기 모드로 최적화
                        optimizeSceneForPreview(scene)
                    }
            } else {
                // 씬이 없으면 기본 메시지 표시
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("미리보기를 불러오는 중...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 200, height: 200)
            }
        }
        .clipped()
    }
    
    // 씬을 미리보기용으로 최적화
    private func optimizeSceneForPreview(_ scene: MultiKeyringScene) {
        
        // 스케일 모드를 aspectFit으로 변경하여 비율 유지
        scene.scaleMode = .aspectFit
        
        // 물리 시뮬레이션 완전 정지
        scene.physicsWorld.speed = 0
        scene.isPaused = false // 렌더링은 계속하되 물리만 정지
        
        // 모든 노드의 애니메이션과 물리 정지
        scene.enumerateChildNodes(withName: "//*") { node, _ in
            node.removeAllActions()
            node.physicsBody?.isDynamic = false
            node.physicsBody?.affectedByGravity = false
        }
    }
}

// MARK: - 이름 입력
extension BundleNameInputView {
    private func bundleNameTextField() -> some View {
        HStack {
            TextField(
                "이름을 입력해주세요",
                text: $bundleName
            )
            .typography(.suit16M25)
            .foregroundStyle(bundleName.count == 0 ? .gray300 : .black100)
            .focused($isTextFieldFocused)
            .onChange(of: bundleName) { _, newValue in
                let regexString = "[^가-힣\\u3131-\\u314E\\u314F-\\u3163a-zA-Z0-9\\s]+"
                var sanitized = newValue.replacingOccurrences(of: regexString, with: "", options: NSString.CompareOptions.regularExpression)

                if sanitized.count > viewModel.maxBundleNameCount {
                    sanitized = String(sanitized.prefix(viewModel.maxBundleNameCount))
                }
                
                if sanitized != bundleName {
                    bundleName = sanitized
                }
            }
            Spacer()
            Text("\(bundleName.count) / \(viewModel.maxBundleNameCount)")
                .typography(.suit13M)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray50)
        )
    }
}

//MARK: - 툴바
extension BundleNameInputView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
            }
        }
    }
    
    private var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // 필수 값 안전 확인
                guard
                    let backgroundId = viewModel.selectedBackground?.id,
                    let carabinerId = viewModel.selectedCarabiner?.id,
                    let carabiner = viewModel.selectedCarabiner
                else {
                    // 값이 없으면 조용히 리턴하거나 에러 상태 표시
                    return
                }
                
                // 선택된 키링들을 카라비너의 최대 개수 길이에 맞춰 직렬화
                // 인덱스에 키링이 없으면 "none"을 저장
                let keyringIds: [String] = (0..<carabiner.maxKeyringCount).map { idx in
                    if let kr = viewModel.selectedKeyringsForBundle[idx],
                       let docId = viewModel.keyringDocumentIdByLocalId[kr.id] {
                        return docId
                    } else {
                        return "none"
                    }
                }
                
                let maxKeyrings = carabiner.maxKeyringCount
                let isMain = viewModel.bundles.isEmpty
                
                // 번들 이름을 미리 캡처 (async 작업 전)
                let bundleNameToSave = bundleName.trimmingCharacters(in: .whitespacesAndNewlines)

                isUploading = true

                viewModel.createBundle(
                    userId: UserManager.shared.userUID,
                    name: bundleNameToSave,
                    selectedBackground: backgroundId,
                    selectedCarabiner: carabinerId,
                    keyrings: keyringIds,
                    maxKeyrings: maxKeyrings,
                    isMain: isMain
                ) { success, bundleId in
                    if success, let bundleId = bundleId {
                        // Firebase 저장 성공 후 번들 이미지 캡처 및 캐싱
                        Task {
                            await captureAndCacheBundleImage(
                                bundleId: bundleId,
                                bundleName: bundleNameToSave
                            )

                            await MainActor.run {
                                isUploading = false
                                router.reset()
                            }
                        }
                    } else {
                        // 실패 처리
                        isUploading = false
                        uploadError = "뭉치 저장에 실패했어요. 잠시 후 다시 시도해 주세요."
                    }
                }
            } label: {
                Text("다음")
            }
            .disabled(
                isUploading ||
                bundleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }
}

// MARK: - 번들 이미지 캡처 및 캐싱
extension BundleNameInputView {
    /// 번들 이미지 캡처 및 BundleImageCache에 저장
    private func captureAndCacheBundleImage(
        bundleId: String,
        bundleName: String
    ) async {
        guard let carabiner = viewModel.selectedCarabiner,
              let background = viewModel.selectedBackground else {
            print("⚠️ [BundleNameInput] 카라비너 또는 배경이 없습니다")
            return
        }

        await withCheckedContinuation { continuation in
            var loadingCompleted = false

            // 키링 데이터 생성
            var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []

            for (index, keyring) in viewModel.selectedKeyringsForBundle.sorted(by: { $0.key < $1.key }) {
                let data = MultiKeyringCaptureScene.KeyringData(
                    index: index,
                    position: CGPoint(
                        x: carabiner.keyringXPosition[index],
                        y: carabiner.keyringYPosition[index]
                    ),
                    bodyImageURL: keyring.bodyImage
                )
                keyringDataList.append(data)
            }

            // MultiKeyringCaptureScene 생성 (캡처 전용, 물리 없음)
            let scene = MultiKeyringCaptureScene(
                keyringDataList: keyringDataList,
                ringType: .basic,
                chainType: .basic,
                backgroundColor: .clear,
                backgroundImageURL: background.backgroundImage,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.size = CGSize(width: 350, height: 466)  // 번들 썸네일 사이즈
            scene.scaleMode = .aspectFill

            // SKView 생성 및 씬 표시
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
                    print("⚠️ [BundleNameInput] 타임아웃 - 로딩 미완료: \(bundleId)")
                } else {
                    // 로딩 완료 후 추가 렌더링 대기
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // PNG 캡처
                if let pngData = await scene.captureToPNG() {
                    // BundleImageCache에 저장
                    BundleImageCache.shared.syncBundle(
                        id: bundleId,
                        name: bundleName,
                        imageData: pngData
                    )
                    print("✅ [BundleNameInput] 번들 이미지 캐시 저장 완료: \(bundleName)")
                } else {
                    print("❌ [BundleNameInput] 캡처 실패: \(bundleId)")
                }

                continuation.resume()
            }
        }
    }
}

#Preview {
    BundleNameInputView(
        router: NavigationRouter(),
        viewModel: CollectionViewModel()
    )
}
