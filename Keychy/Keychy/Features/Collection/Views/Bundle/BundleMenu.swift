//
//  BundleMenu.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI

struct BundleMenu: View {
    let onNameEdit: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let isMain: Bool
    
    @State private var isAppearing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {

            // 뭉치 이름 수정 버튼
            Button(action: onNameEdit) {
                HStack(spacing: 8) {
                    Image(.editNameIcon)
                        .resizable()
                        .frame(width: 25, height: 25)
                    
                    Text("뭉치 이름 수정")
                        .typography(.suit16M)
                        .foregroundColor(.gray600)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 편집 버튼
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image(.editIcon)
                        .resizable()
                        .frame(width: 25, height: 25)
                    
                    Text("편집")
                        .typography(.suit16M)
                        .foregroundColor(.gray600)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 삭제 버튼
            if !isMain {
                Button(action: onDelete) {
                    HStack(spacing: 8) {
                        Image(.trash)
                            .resizable()
                            .frame(width: 25, height: 25)
                        
                        Text("삭제")
                            .typography(.suit16M)
                            .foregroundColor(.pink)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(width: 170)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .scaleEffect(isAppearing ? 1.0 : 0.8, anchor: .topTrailing)
        .opacity(isAppearing ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
}
