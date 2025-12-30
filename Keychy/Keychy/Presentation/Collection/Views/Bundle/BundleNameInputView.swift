//
//  BundleNameInputView.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SwiftUI
import SpriteKit

struct BundleNameInputView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var viewModel: CollectionViewModel
    
    /// 번들 이름 입력용 State
    @State private var bundleName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0

    @State private var textColor: Color = .gray300

    // 업로드 상태
    @State private var isUploading: Bool = false
    @State private var uploadError: String?

    // 욕설 필터링
    @State private var validationMessage: String = ""
    @State private var hasProfanity: Bool = false
    
    @State private var morePadding: CGFloat = 0
    
    // 선택된 키링들을 ViewModel에서 가져옴
    private var selectedKeyrings: [Int: Keyring] {
        viewModel.selectedKeyringsForBundle
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 20) {
                viewModel.keyringSceneView()
                
                // 번들 이름 입력 섹션
                bundleNameTextField()
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 60 + morePadding)
            customNavigationBar
            
            if isUploading {
                Color.black20
                    .ignoresSafeArea()
                LoadingAlert(type: .longWithKeychy, message: "키링 뭉치를 생성하고 있어요")
            }
        }
        .padding(.bottom, -keyboardHeight)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .scrollDismissesKeyboard(.never)
        .onAppear {
            // 키보드 자동 활성화
            isTextFieldFocused = true

            viewModel.hideTabBar()
            
            if getBottomPadding(34) == 0 {
                morePadding = 40
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
        // 키보드 올라옴 내려옴을 감지하는 notification center, 개발록 '키보드가 올라오면서 화면을 가릴 때'에서 소개한 내용과 같습니다.
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
                UIView.setAnimationsEnabled(false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
            UIView.setAnimationsEnabled(false)
        }
    }
}

// MARK: - 이름 입력
extension BundleNameInputView {
    private func bundleNameTextField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(
                    "뭉치 이름을 입력해주세요",
                    text: $bundleName
                )
                .typography(.notosans16R)
                .foregroundStyle(textColor)
                .focused($isTextFieldFocused)
                .tint(.main500)
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

                    // 욕설 체크
                    if bundleName.isEmpty {
                        validationMessage = ""
                        hasProfanity = false
                    } else {
                        let profanityCheck = TextFilter.shared.validateText(bundleName)
                        if !profanityCheck.isValid {
                            validationMessage = profanityCheck.message ?? "부적절한 단어가 포함되어 있어요"
                            hasProfanity = true
                        } else {
                            validationMessage = ""
                            hasProfanity = false
                        }
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

            // 유효성 메시지
            if !validationMessage.isEmpty {
                Text(validationMessage)
                    .typography(.suit14M)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
}

//MARK: - 툴바
extension BundleNameInputView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            EmptyView()
        } trailing: {
            TextToolbarButton(title: "완료") {
                handleNextButtonTap()
            }
            .disabled(
                isUploading ||
                bundleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                hasProfanity
            )
        }
    }
    
    private func handleNextButtonTap() {
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

        // 키보드를 내린 후 로딩 알럿이 띄워지도록 함
        isTextFieldFocused = false

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
                
                // 생성된 번들을 selectedBundle에 할당
                // createBundle의 completion이 배열 업데이트 후 호출되므로 안전
                viewModel.selectedBundle = viewModel.bundles.first { $0.documentId == bundleId }
                router.reset()
                router.push(.bundleInventoryView)
                // 네비게이션: 상세 페이지로 이동
                router.push(.bundleDetailView)
            } else {
                // 실패 처리
                isUploading = false
                uploadError = "뭉치 저장에 실패했어요. 잠시 후 다시 시도해 주세요."
            }
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
