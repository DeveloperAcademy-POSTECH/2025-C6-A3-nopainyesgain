//
//  KeyringMenu.swift
//  Keychy
//
//  Created by Jini on 11/5/25.
//

import SwiftUI

struct KeyringMenu: View {
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    @State private var isAppearing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메뉴
                VStack(alignment: .leading, spacing: 25) {

                    // 편집 버튼
                    Button(action: onEdit) {
                        HStack(spacing: 8) {
                            Image("Pencil")
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            Text("키링 편집")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    // 복사 버튼
                    Button(action: onCopy) {
                        HStack(spacing: 8) {
                            Image("Copy")
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            Text("복사")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 삭제 버튼
                    Button(action: onDelete) {
                        HStack(spacing: 8) {
                            Image("Trash")
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            Text("삭제")
                                .typography(.suit16M)
                                .foregroundColor(.pink100)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(width: 170, height: 186)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
                .scaleEffect(isAppearing ? 1.0 : 0.8, anchor: .topTrailing)
                .opacity(isAppearing ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
}
