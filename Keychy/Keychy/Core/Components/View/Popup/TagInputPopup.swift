//
//  TagInputPopup.swift
//  Keychy
//
//  Created by Jini on 11/4/25.
//

import SwiftUI

struct TagInputPopup: View {
    
    enum TagPopupType {
        case add, edit
        var title: String { self == .add ? "태그 추가하기" : "태그 이름 수정" }
        var confirmText: String { self == .add ? "추가" : "완료" }
    }
    
    let type: TagPopupType
    @Binding var tagName: String
    let availableTags: [String]
    let onCancel: () -> Void
    let onConfirm: (String) -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var showDuplicateTagError = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 제목
            Text(type.title)
                .typography(.suit17B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
            
            HStack {
                TextField("태그를 입력해주세요", text: $tagName)
                    .typography(.suit16M)
                    .foregroundColor(.black100)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .focused($isTextFieldFocused)
                    .onChange(of: tagName) { oldValue, newValue in
                        if newValue.count > 10 {
                            tagName = String(newValue.prefix(10))
                        }
                        showDuplicateTagError = availableTags.contains(newValue)
                    }
                    .submitLabel(.done)
                
                if !tagName.isEmpty {
                    Button(action: {
                        tagName = ""
                    }) {
                        Image("EmptyIcon")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white100)
            )
            .padding(.top, 21)
            .padding(.bottom, 5)
            
            HStack {
                Text(showDuplicateTagError ? "이미 사용 중인 태그 이름입니다." : "")
                    .typography(.suit14M)
                    .foregroundColor(.error)
                    .opacity(showDuplicateTagError ? 1 : 0)
                    
                Spacer()
            }
            .padding(.bottom, 20)

            // 버튼들
            HStack(spacing: 16) {
                // 취소 버튼
                Button(action: onCancel) {
                    Text("취소")
                        .typography(.suit17SB)
                        .foregroundColor(.black100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.black10)
                        )
                }
                .buttonStyle(.plain)
                
                // 확인 버튼
                Button {
                    if !showDuplicateTagError, !tagName.isEmpty {
                        onConfirm(tagName)
                    }
                } label:  {
                    Text(type.confirmText)
                        .typography(.suit17B)
                        .foregroundColor(.white100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.main500)
                        )
                }
                .buttonStyle(.plain)
                .disabled(tagName.isEmpty || showDuplicateTagError)
            }
            
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 230)
        .onAppear {
            // 팝업 뜰 때 자동으로 키보드 올리기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }

}
