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
    private func optimizeSceneForPreview(_ scene: CarabinerScene) {
        
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
            Button("완료") {
                createNewBundle()
                router.reset()
            }
            .disabled(
                bundleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }
}

// MARK: - 번들 저장 로직
extension BundleNameInputView {
    private func createNewBundle() {
        guard let carabiner = viewModel.selectedCarabiner else { return }
        
        // 선택된 키링들을 인덱스 순서대로 배열로 변환 (딕셔너리 키 순서 보장)
        var keyringArray: [Keyring] = []
        
        // 카라비너의 최대 키링 수만큼 순서대로 처리
        for index in 0..<carabiner.maxKeyringCount {
            if let keyring = selectedKeyrings[index] {
                keyringArray.append(keyring)
            }
        }
        
        // 새로운 KeyringBundle 생성 (현재 모델이 keyrings: [String]이므로 ID로 저장)
        let newBundle = KeyringBundle(
            name: bundleName.trimmingCharacters(in: .whitespacesAndNewlines),
            selectedBackground: "cherries", // 임시로 체리 배경
            selectedCarabiner: carabiner.carabinerImage,
            keyrings: keyringArray.map { $0.id.uuidString }, // UUID를 String으로 변환
            maxKeyrings: carabiner.maxKeyringCount,
            isMain: viewModel.bundles.isEmpty, // 첫 번째 번들이면 메인으로 설정
            createdAt: Date()
        )
        
        // ViewModel의 bundles에 추가
        viewModel.bundles.append(newBundle)
        
        // 저장 완료 후 씬 정리
        viewModel.bundlePreviewScene = nil
        viewModel.selectedKeyringsForBundle = [:]
    }
}

#Preview {
    BundleNameInputView(
        router: NavigationRouter(),
        viewModel: CollectionViewModel()
    )
}
