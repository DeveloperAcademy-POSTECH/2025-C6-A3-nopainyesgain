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
                VStack(alignment: .leading, spacing: 25) {

                    // 편집 버튼
                    Button(action: onEdit) {
                        HStack(spacing: 8) {
                            Image("Pencil")
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            Text("정보 수정")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isMyKeyring {
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
                    }
                    
                    // 삭제 버튼
                    Button(action: onDelete) {
                        HStack(spacing: 8) {
                            Image("Trash")
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
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(width: menuWidth, height: menuHeight)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
                .scaleEffect(isAppearing ? 1.0 : 0.8, anchor: .topTrailing)
                .opacity(isAppearing ? 1.0 : 0.0)
                .position(
                    x: geometry.size.width - menuWidth / 2 - 16,
                    y: position.maxY + menuHeight + adaptiveOffset()
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
    
    // 기기별 추가 오프셋 조절
    private func adaptiveOffset() -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return isMyKeyring ? 28 : 56
        }
        
        let screenHeight = window.screen.bounds.height
        
        // SE (safeAreaInsets.top < 25) 높이 667pt
        if window.safeAreaInsets.top < 25 {
            return isMyKeyring ? -18 : 10  // SE에서는 더 작은 값
        }
        
        // 노치 기기 (14, 15 등) 높이 844pt
        if screenHeight < 850 {
            return isMyKeyring ? 8 : 36
        }
        
        // 노치 기기 (16 Pro 등) 높이 852pt
        return isMyKeyring ? 28 : 56
    }
}
