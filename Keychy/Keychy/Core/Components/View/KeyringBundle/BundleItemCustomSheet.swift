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
    private let mediumRatio: CGFloat = 0.32
    private let largeRatio: CGFloat = 0.8
    
    // 계산된 높이 값들
    private var smallHeight: CGFloat {
        screenHeight * smallRatio
    }
    
    private var mediumHeight: CGFloat {
        screenHeight * mediumRatio
    }
    
    private var largeHeight: CGFloat {
        screenHeight * largeRatio
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 인디케이터
            VStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(.gray300)
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture)
            
            ScrollView {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .gesture(dragGesture)
        }
        .frame(height: sheetHeight)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .stroke(.gray50, lineWidth: 1)
                .shadow(color: .black100.opacity(0.15), radius: 9, x: 0, y: 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .onAppear {
            if sheetHeight == 360 {
                sheetHeight = mediumHeight // 기본값을 중간 크기로 설정
            }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
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

