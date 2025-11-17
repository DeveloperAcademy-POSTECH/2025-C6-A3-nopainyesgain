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
    @State private var morePadding: CGFloat = 0

    // 욕설 필터링
    @State private var validationMessage: String = ""
    @State private var hasProfanity: Bool = false
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 20) {
                viewModel.keyringSceneView()
                
                bundleNameTextField
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 100)
            .frame(maxHeight: .infinity)
            .padding(.bottom, max(screenHeight/2 - keyboardHeight, 20))
        }
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .top) {
            customNavigationBar
                .adaptiveTopPadding()
                .padding(.top, morePadding)
        }
        .onAppear {
            if let bundle = viewModel.selectedBundle {
                bundleName = bundle.name
                viewModel.loadBundleImageFromCache(bundle: bundle)
            }
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
            if getBottomPadding(0) == 0 {
                morePadding = 20
            }
        }
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
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
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        } center: {
            EmptyView()
        } trailing: {
            NextToolbarButton {
                handleCheckButtonTap()
            }
            .disabled(isUpdating || bundleName.isEmpty || bundleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasProfanity)
            .frame(width: 62, height: 44)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 100))
        }
    }
    
    private func handleCheckButtonTap() {
        guard let bundle = viewModel.selectedBundle else { return }
        
        isUpdating = true
        viewModel.updateBundleName(bundle: bundle, newName: bundleName.trimmingCharacters(in: .whitespacesAndNewlines)) { [weak viewModel] success in
            DispatchQueue.main.async {
                self.isUpdating = false
                if success {
                    viewModel?.selectedBundle?.name = self.bundleName.trimmingCharacters(in: .whitespacesAndNewlines)
                    router.pop()
                }
            }
        }
    }
}
