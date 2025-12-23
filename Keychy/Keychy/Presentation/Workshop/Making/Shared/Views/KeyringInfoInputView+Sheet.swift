//
//  KeyringInfoInputView+Sheet.swift
//  Keychy
//
//  Bottom sheet and input components
//

import SwiftUI

// MARK: - Info Sheet
extension KeyringInfoInputView {
    var infoSheet: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("정보")
                        .typography(.suit17B)
                    Spacer()
                }
                .padding(.top, 29)

                if sheetDetent != .height(76) {
                    textNameView
                        .padding(.bottom, 30)
                        .padding(.top, 19)

                    textMemoView
                        .padding(.bottom, 30)

                    selectTagsView
                }

                Spacer(minLength: 0)
            }
            .background(
                GeometryReader { contentGeometry in
                    Color.clear.preference(
                        key: SheetHeightPreferenceKey.self,
                        value: contentGeometry.size.height
                    )
                }
            )
            .onPreferenceChange(SheetHeightPreferenceKey.self) { height in
                if height > 0 {
                    measuredSheetHeight = height
                }
            }
        }
        .scrollDisabled(true)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetDetent != .height(76) ? .white100 : .clear)
        .dismissKeyboardOnTap()
    }
}

// MARK: - Preference Key for Sheet Height
struct SheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 395
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Name Input View
extension KeyringInfoInputView {
    var textNameView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이름 (필수)")
                .typography(.suit16B)
                .foregroundStyle(.black100)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField(
                        "이름을 입력해주세요",
                        text: $viewModel.nameText
                    )
                    .foregroundStyle(viewModel.nameText.isEmpty ? .gray300 : .black100)
                    .focused($isFocused)
                    .onChange(of: viewModel.nameText) { _, newValue in
                        // 글자수 제한만 적용 (특수문자 허용)
                        var sanitized = newValue

                        if sanitized.count > viewModel.maxTextCount {
                            sanitized = String(sanitized.prefix(viewModel.maxTextCount))
                        }

                        if sanitized != viewModel.nameText {
                            viewModel.nameText = sanitized
                        }

                        textCount = viewModel.nameText.count

                        // 욕설 체크
                        if viewModel.nameText.isEmpty {
                            validationMessage = ""
                            hasProfanity = false
                        } else {
                            let profanityCheck = TextFilter.shared.validateText(viewModel.nameText)
                            if !profanityCheck.isValid {
                                validationMessage = profanityCheck.message ?? "부적절한 단어가 포함되어 있어요"
                                hasProfanity = true
                            } else {
                                validationMessage = ""
                                hasProfanity = false
                            }
                        }
                    }
                    .typography(.notosans15M)
                    /// 커서 표시기 색상
                    .tint(.main500)

                    Text("\(textCount)/\(viewModel.maxTextCount)")
                        .typography(.suit13M)
                        .foregroundStyle(.gray300)
                }
                .padding(.vertical, 13.5)
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
}

// MARK: - Memo Input View
extension KeyringInfoInputView {
    var textMemoView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("메모")
                .typography(.suit16B)
                .foregroundStyle(.black100)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.memoText)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .typography(.notosans15M)
                    .foregroundStyle(.black100)
                
                    /// 커서 표시기 색상
                    .tint(.main500)
                    .frame(minHeight: 80, maxHeight: 150)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .onChange(of: viewModel.memoText) { _, newValue in
                        memoTextCount = newValue.count
                        if newValue.count > viewModel.maxMemoCount {
                            viewModel.memoText = String(newValue.prefix(viewModel.maxMemoCount))
                            memoTextCount = viewModel.maxMemoCount
                        }
                    }

                if viewModel.memoText.isEmpty {
                    Text("메모(선택)")
                        .typography(.notosans15M)
                        .foregroundColor(.gray300)
                        .padding(.top, 18)
                        .padding(.leading, 17)
                        .allowsHitTesting(false)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray50)
            )
        }
    }
}
