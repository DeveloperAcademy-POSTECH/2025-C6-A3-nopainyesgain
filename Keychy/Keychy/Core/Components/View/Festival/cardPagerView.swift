//
//  cardPagerView.swift
//  Keychy
//
//  Created by seo on 11/23/25.
//

import SwiftUI


// MARK: - 메인 Pager View
struct cardPagerView<Content: View>: View {
    let pageCount: Int
    let cardWidth: CGFloat = screenWidth * 0.75
    let cardSpacing: CGFloat = 17
    
    @Binding var currentPage: Int
    @ViewBuilder let content: (Int) -> Content
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cardSpacing) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        GeometryReader { cardGeometry in
                            let minX = cardGeometry.frame(in: .global).minX
                            let screenMidX = screenWidth/2
                            let cardMidX = cardWidth / 2
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                content(index)
                            }
                        }
                        .frame(width: cardWidth)
                        .id(index)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, screenWidth * 0.125)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding(
                get: { currentPage as Int? },
                set: { currentPage = $0 ?? 0 }
            ))
        }
        
    }
}
