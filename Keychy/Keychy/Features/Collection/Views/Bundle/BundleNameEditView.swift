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
    @State private var textColor: UIColor = .gray300
    
    @State private var isUpdating: Bool = false
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 20) {
                // 뭉치 캡쳐 씬으로 수정 필요
                Rectangle()
                    .fill(.gray100)
                    .aspectRatio(5/7, contentMode: .fit)
                bundleNameTextField
                Spacer().frame(height: geo.size.height * 0.3)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear {
            if let bundle = viewModel.selectedBundle {
                bundleName = bundle.name
            }
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar {
            backButton
            checkButton
        }
        .navigationBarBackButtonHidden(true)
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
            .disabled(isUpdating || bundleName.isEmpty || bundleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.glassProminent)
        }
    }
}
