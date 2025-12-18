//
//  KeyringMenu.swift
//  Keychy
//
//  Created by Jini on 11/5/25.
//

import SwiftUI

struct KeyringMenu: View {
    let position: CGRect
    let isMyKeyring: Bool
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    private let menuWidth: CGFloat = 165
    private var menuHeight: CGFloat {
        isMyKeyring ? 170 : 115  // 복사 버튼 있으면 170, 없으면 115
    }
    
    @State private var isAppearing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메뉴
                VStack(alignment: .leading, spacing: 5) {
                    // 편집 버튼
                    Button(action: onEdit) {
                        HStack(spacing: 8) {
                            Image(.pencil)
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            Text("정보 수정")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isMyKeyring {
                        // 복사 버튼
                        Button(action: onCopy) {
                            HStack(spacing: 8) {
                                Image(.copy)
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                
                                Text("복사")
                                    .typography(.suit16M)
                                    .foregroundColor(.gray600)
                                
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                            .contentShape(Rectangle())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 삭제 버튼
                    Button(action: onDelete) {
                        HStack(spacing: 8) {
                            Image(.trash)
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            Text("삭제")
                                .typography(.suit16M)
                                .foregroundColor(.pink)
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 20)
                .frame(width: menuWidth, height: menuHeight)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
                .scaleEffect(isAppearing ? 1.0 : 0.8, anchor: .topTrailing)
                .opacity(isAppearing ? 1.0 : 0.0)
                .position(
                    x: geometry.size.width - menuWidth / 2 - 16,
                    y: position.maxY + 8 + menuHeight / 2
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
}
