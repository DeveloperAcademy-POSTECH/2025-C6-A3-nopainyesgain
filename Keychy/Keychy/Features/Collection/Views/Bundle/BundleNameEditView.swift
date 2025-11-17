//
//  BundleNameEditVIew.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI

struct BundleNameEditView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    @State private var bundleName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var textColor: Color = .gray300
    @State private var keyboardHeight: CGFloat = 0

    @State private var isUpdating: Bool = false

    // 욕설 필터링
    @State private var validationMessage: String = ""
    @State private var hasProfanity: Bool = false
    var body: some View {
        VStack(spacing: 20) {
            viewModel.keyringSceneView()
            
            bundleNameTextField
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 100)
        .frame(maxHeight: .infinity)
        .onAppear {
            if let bundle = viewModel.selectedBundle {
                bundleName = bundle.name
                viewModel.loadBundleImageFromCache(bundle: bundle)
            }
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backButton
            checkButton
        }
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
        .padding(.bottom, max(screenHeight/2 - keyboardHeight, 20))
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

extension BundleNameEditView {
    private var bundleNameTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(
                    "뭉치 이름을 입력해주세요.",
                    text: $bundleName
                )
                .typography(bundleName.isEmpty ? .notosans16R : .suit16M)
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
                    if bundleName.isEmpty {
                        textColor = .gray300
                    } else {
                        textColor = .black100
                    }

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
                    .foregroundStyle(.gray300)
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

// MARK: - 툴바

extension BundleNameEditView {
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                //TODO: 에셋 이미지로 변경 필요
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.glass)
        }
    }
    
    private var checkButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.updateBundleName(bundle: viewModel.selectedBundle!, newName: bundleName.trimmingCharacters(in: .whitespacesAndNewlines)) { [weak viewModel] success in
                    DispatchQueue.main.async {
                        self.isUpdating = false
                        if success {
                            viewModel?.selectedBundle?.name = self.bundleName.trimmingCharacters(in: .whitespacesAndNewlines)
                            router.pop()
                        }
                    }
                }
            } label: {
                if isUpdating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white100))
                        .scaleEffect(0.8)
                } else {
                    Image(.recCheck)
                        .foregroundStyle(.white100)
                }
            }
            .disabled(isUpdating || bundleName.isEmpty || bundleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasProfanity)
            .buttonStyle(.glassProminent)
        }
    }
}
