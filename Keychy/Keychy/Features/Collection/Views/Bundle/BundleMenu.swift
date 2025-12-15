//
//  BundleMenu.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI

struct BundleMenu: View {
    let position: CGRect
    let onNameEdit: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let isMain: Bool
    
    private let menuWidth: CGFloat = 185
    private var menuHeight: CGFloat {
        isMain ? 120 : 175  // 메인 뭉치면 삭제 버튼 없음
    }
    
    @State private var isAppearing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메뉴
                VStack(alignment: .leading, spacing: 5) {

                    // 뭉치 이름 수정 버튼
                    Button(action: onNameEdit) {
                        HStack(spacing: 8) {
                            Image(.editNameIcon)
                            
                            Text("뭉치 이름 변경")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 편집 버튼
                    Button(action: onEdit) {
                        HStack(spacing: 8) {
                            Image(.bundleEditIcon)
                            
                            Text("뭉치 수정")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 삭제 버튼
                    if !isMain {
                        Button(action: onDelete) {
                            HStack(spacing: 8) {
                                Image(.trash)
                                
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
