//
//  FestivalKeyringContextMenu.swift
//  Keychy
//
//  Created by Jini on 11/25/25.
//

import SwiftUI

// 페스티벌 컨텍스트 메뉴
// 키링 교체 및 회수 기능 제공
struct FestivalKeyringContextMenu: View {
    let categoryName: String
    let position: CGRect
    let onRename: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    // 메뉴 크기
    private let menuWidth: CGFloat = 165
    private let menuHeight: CGFloat = 115
    
    @State private var isAppearing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                // 메뉴
                VStack(alignment: .leading, spacing: 25) {
                    // 태그 이름
                    Text(categoryName)
                        .typography(.notosans13M)
                        .foregroundColor(.gray500)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    // 이름 변경 버튼
                    Button(action: onRename) {
                        HStack(spacing: 8) {
                            Image(.recDeleteFill)
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            Text("교체")
                                .typography(.suit16M)
                                .foregroundColor(.gray600)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // 삭제 버튼
                    Button(action: onDelete) {
                        HStack(spacing: 8) {
                            Image(.pencil)
                                .resizable()
                                .frame(width: 25, height: 25)
                            
                            Text("회수")
                                .typography(.suit16M)
                                .foregroundColor(.pink)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(width: menuWidth, height: menuHeight)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
                .scaleEffect(isAppearing ? 1.0 : 0.8, anchor: .top)
                .opacity(isAppearing ? 1.0 : 0.0)
                .position( // 메뉴 위치
                    x: calculateSafeX(in: geometry),
                    y: position.maxY + adaptiveOffset()
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
    
    // 화면 밖으로 나가지 않게 안전한 X 위치 계산
    private func calculateSafeX(in geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let desiredX = position.midX + 50
        
        let leftLimit: CGFloat = menuWidth / 2 + 20
        let rightLimit = screenWidth - menuWidth / 2 - 20
        
        if desiredX < leftLimit {
            return leftLimit
        } else if desiredX > rightLimit {
            return rightLimit
        }
        
        return desiredX
    }
    
    // 기기별 추가 오프셋 조절
    private func adaptiveOffset() -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return 20
        }
        
        let screenHeight = window.screen.bounds.height
        
        // SE (safeAreaInsets.top < 25) 높이 667pt
        if window.safeAreaInsets.top < 25 {
            return 56
        }
        
        // 노치 기기 (14, 15 등) 높이 844pt
        if screenHeight < 850 {
            return 32
        }
        
        // 노치 기기 (16 Pro 등) 높이 852pt
        return 20
    }
}
