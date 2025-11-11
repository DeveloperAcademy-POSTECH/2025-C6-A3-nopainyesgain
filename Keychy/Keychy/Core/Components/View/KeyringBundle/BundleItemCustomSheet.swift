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
    
    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .contentShape(Rectangle())
                .highPriorityGesture(dragGesture)
            
            ScrollView {
                content
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: sheetHeight)
            .gesture(dragGesture)
        }
        .frame(height: sheetHeight)
        .background(.ultraThinMaterial)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let newHeight = sheetHeight - value.translation.height
                if newHeight >= 360 && newHeight <= 600 {
                    sheetHeight = newHeight
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    sheetHeight = sheetHeight < 555 ? 360 : 600
                }
            }
    }
}
