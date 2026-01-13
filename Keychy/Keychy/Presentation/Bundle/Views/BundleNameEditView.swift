//
//  BundleNameEditVIew.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI

struct BundleNameEditView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var collectionVM: CollectionViewModel
    @State var bundleVM: BundleViewModel
    
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
                bundleVM.bundleCaptureSceneView()
                
                bundleNameTextField
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 60 + morePadding)
            
            customNavigationBar
        }
        .padding(.bottom, -keyboardHeight)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .withToast(position: .default)
        .scrollDismissesKeyboard(.never)
        .onAppear {
            if let bundle = bundleVM.selectedBundle {
                bundleName = bundle.name
                bundleVM.loadBundleImageFromCache(bundle: bundle)
            }
            isTextFieldFocused = true
            
            // SE기기는 기기 상단이 막혀있고, 16기기는 상단이 뚫려있는(다이나믹 아일랜드) 기기 형태라서 다이나믹 아일랜드가 있는 기기를 위한 추가적인 여백을 계산해 넣습니다.
            if getBottomPadding(34) == 0 {
                morePadding = 40
            }
            TabBarManager.hide()
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
                .typography(bundleName.isEmpty ? .notosans16R : .notosans16R25)
                .foregroundStyle(textColor)
                .focused($isTextFieldFocused)
                .tint(.main500)
                .onChange(of: bundleName) { _, newValue in
                    let regexString = "[^가-힣\\u3131-\\u314E\\u314F-\\u3163a-zA-Z0-9\\s]+"
                    var sanitized = newValue.replacingOccurrences(of: regexString, with: "", options: NSString.CompareOptions.regularExpression)

                    if sanitized.count > bundleVM.maxBundleNameCount {
                        sanitized = String(sanitized.prefix(bundleVM.maxBundleNameCount))
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

                Text("\(bundleName.count) / \(bundleVM.maxBundleNameCount)")
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
        } center: {
            EmptyView()
        } trailing: {
            NextToolbarButton {
                handleCheckButtonTap()
            }
            .disabled(isUpdating || bundleName.isEmpty || bundleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasProfanity)
        }
    }
    
    private func handleCheckButtonTap() {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }

        guard let bundle = bundleVM.selectedBundle else { return }

        isUpdating = true
        
        // pop 전에 현재 구성 id를 ViewModel에 저장
        // 현재 번들의 배경/카라비너 resolve
        let bg = bundleVM.resolveBackground(from: bundle.selectedBackground)
        let cb = bundleVM.resolveCarabiner(from: bundle.selectedCarabiner)
        
        // BundleDetailView와 동일 규칙으로 id 생성
        let bgId = bundleVM.makeBackgroundId(bg)
        let cbId = bundleVM.makeCarabinerId(cb)
        
        // keyringsId는 현재 번들의 구성 기반으로 재구성
        Task {
            var krList: [MultiKeyringScene.KeyringData] = []
            if let carabiner = cb {
                krList = await bundleVM.createKeyringDataList(bundle: bundle, carabiner: carabiner)
            }
            let krId = bundleVM.makeKeyringsId(krList)
            
            await MainActor.run {
                bundleVM.returnBackgroundId = bgId
                bundleVM.returnCarabinerId = cbId
                bundleVM.returnKeyringsId = krId
            }
        }
        
        bundleVM.updateBundleName(bundle: bundle, newName: bundleName.trimmingCharacters(in: .whitespacesAndNewlines)) { success in
            DispatchQueue.main.async {
                self.isUpdating = false
                if success {
                    bundleVM.selectedBundle?.name = self.bundleName.trimmingCharacters(in: .whitespacesAndNewlines)
                    router.pop()
                }
            }
        }
    }
}
