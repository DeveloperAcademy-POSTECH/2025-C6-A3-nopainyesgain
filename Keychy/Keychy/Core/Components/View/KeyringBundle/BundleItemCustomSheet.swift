//
//  BundleItemCustomSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI

struct BundleItemCustomSheet<Content: View>: View {
    @Binding var sheetHeight: CGFloat
    let content: Content
    
    // 화면 높이 기준 비율
    private let smallRatio: CGFloat = 0.1
    private let mediumRatio: CGFloat = 0.43  
    private let largeRatio: CGFloat = 0.8
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let smallHeight = screenHeight * smallRatio
            let mediumHeight = screenHeight * mediumRatio
            let largeHeight = screenHeight * largeRatio
            
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .contentShape(Rectangle())
                    .highPriorityGesture(dragGesture(screenHeight: screenHeight))
                
                ScrollView {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .gesture(dragGesture(screenHeight: screenHeight))
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .frame(height: sheetHeight)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.ultraThickMaterial)
                    .stroke(.gray50, lineWidth: 1)
                    .shadow(color: .black100.opacity(0.15), radius: 9, x: 0, y: 0)
            )
            .onAppear {
                if sheetHeight == 200 {
                    sheetHeight = mediumHeight // 기본값을 중간 크기로 설정
                }
            }
        }
    }
    
    private func dragGesture(screenHeight: CGFloat) -> some Gesture {
        let smallHeight = screenHeight * smallRatio
        let mediumHeight = screenHeight * mediumRatio
        let largeHeight = screenHeight * largeRatio
        
        return DragGesture()
            .onChanged { value in
                let newHeight = sheetHeight - value.translation.height
                if newHeight >= smallHeight && newHeight <= largeHeight {
                    sheetHeight = newHeight
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    // 3단계로 스냅
                    let midSmallMedium = (smallHeight + mediumHeight) / 2
                    let midMediumLarge = (mediumHeight + largeHeight) / 2
                    
                    if sheetHeight < midSmallMedium {
                        sheetHeight = smallHeight
                    } else if sheetHeight < midMediumLarge {
                        sheetHeight = mediumHeight
                    } else {
                        sheetHeight = largeHeight
                    }
                }
            }
    }
}

