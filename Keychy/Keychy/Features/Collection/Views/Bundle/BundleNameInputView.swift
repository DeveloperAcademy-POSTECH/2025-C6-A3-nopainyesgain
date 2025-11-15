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
    
    @State private var textColor: Color = .gray300
    
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
                viewModel.keyringSceneView(widthSize: geo.size.width - 175.58)
                
                // 번들 이름 입력 섹션
                bundleNameTextField()
                    .padding(.horizontal, 20)
                //TODO: 업로드 중 로티 추가
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

// MARK: - 이름 입력
extension BundleNameInputView {
    private func bundleNameTextField() -> some View {
        HStack {
            TextField(
                "이름을 입력해주세요",
                text: $bundleName
            )
            .typography(.suit16M25)
            .foregroundStyle(textColor)
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
                
                textColor = (bundleName.count == 0 ? .gray300 : .black100)
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
                        // Firebase 저장 성공 후 ViewModel의 이미지를 캐시에 저장
                        saveBundleImageToCache(
                            bundleId: bundleId,
                            bundleName: bundleNameToSave
                        )

                        isUploading = false
                        router.reset()
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

// MARK: - 번들 이미지 캐싱
extension BundleNameInputView {
    /// ViewModel에 저장된 번들 이미지를 BundleImageCache에 저장
    private func saveBundleImageToCache(
        bundleId: String,
        bundleName: String
    ) {
        guard let imageData = viewModel.bundleCapturedImage else {
            return
        }

        // BundleImageCache에 저장
        BundleImageCache.shared.syncBundle(
            id: bundleId,
            name: bundleName,
            imageData: imageData
        )
    }
}
