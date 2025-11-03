//
//  CategoryContextMenu.swift
//  Keychy
//
//  Created by Jini on 11/3/25.
//

import SwiftUI

// 카테고리 컨텍스트 메뉴
// 태그 이름 변경 및 삭제 기능을 제공하는 팝업 메뉴
struct CategoryContextMenu: View {
    let categoryName: String
    let position: CGRect
    let onRename: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // TODO: Dim용 배경색 수정
            // 배경 탭하면 닫기
            Color.black20
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // 메뉴
            VStack(alignment: .leading, spacing: 25) {
                // 태그 이름
                Text(categoryName)
                    .typography(.suit13M)
                    .foregroundColor(.gray500)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                
                // 이름 변경 버튼
                Button(action: onRename) {
                    HStack(spacing: 8) {
                        Image("Pencil")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("태그 이름 변경")
                            .typography(.suit16M)
                            .foregroundColor(.black100)
                    }
                }
                .buttonStyle(.plain)
                
                // 삭제 버튼
                Button(action: onDelete) {
                    HStack(spacing: 8) {
                        Image("Trash")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("삭제")
                            .typography(.suit16M)
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 34)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
            .frame(width: 170)
            .position( // 메뉴 위치
                x: position.midX + 50,
                y: position.maxY + 20
            )
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: true)
    }
}
