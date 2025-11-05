//
//  TagInputPopup.swift
//  Keychy
//
//  Created by Jini on 11/4/25.
//

import SwiftUI

struct TagInputPopup: View {
    @Binding var tagName: String
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // 제목
            Text("태그 이름 수정")
                .typography(.suit17B)
                .foregroundColor(.black100)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            HStack {
                TextField("태그 이름", text: $tagName)
                    .typography(.suit16M)
                    .foregroundColor(.black100)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .focused($isTextFieldFocused)
                    .onChange(of: tagName) { oldValue, newValue in
                        if newValue.count > 10 {
                            tagName = String(newValue.prefix(10))
                        }
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
                    .fill(.gray50)
            )
            .padding(.bottom, 19)

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
                Button(action: onConfirm) {
                    Text("완료")
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
                .disabled(tagName.isEmpty)
            }
            
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 204)
        .onAppear {
            // 팝업 뜰 때 자동으로 키보드 올리기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }

}

#Preview {
    TagInputPopup(tagName: .constant("태그"), onCancel: {}, onConfirm: {})
}
