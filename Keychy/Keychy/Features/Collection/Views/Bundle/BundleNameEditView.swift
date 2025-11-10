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
    @State private var keyboardHeight: CGFloat = 0
    @State private var textColor: UIColor = .gray300
    
    @State private var isUpdating: Bool = false
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 20) {
                // 뭉치 캡쳐 씬으로 수정 필요
                Rectangle()
                    .fill(.gray100)
                    .frame(height: geo.size.height / 4)
                bundleNameTextField
            }
            .padding(.bottom, max(380 - keyboardHeight, 20))
        }
        .onAppear {
            if let bundle = viewModel.selectedBundle {
                bundleName = bundle.name
            }
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
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

extension BundleNameEditView {
    private var bundleNameTextField: some View {
        HStack {
            TextField(
                "뭉치 이름을 입력해주세요.",
                text: $bundleName
            )
            .typography(.notosans16R)
            .foregroundStyle(bundleName.isEmpty ? .gray300 : .black100)
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
    }
}
