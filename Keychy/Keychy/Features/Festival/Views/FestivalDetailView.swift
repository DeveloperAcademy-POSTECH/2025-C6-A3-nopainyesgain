//
//  FestivalDetailView.swift
//  Keychy
//
//  Created by seo on 11/23/25.
//

import SwiftUI

struct FestivalDetailView: View {
    @Bindable var router: NavigationRouter<FestivalRoute>
    
    var body: some View {
        ZoomableView(minZoomScale: 0.5, maxZoomScale: 3.0) {
            // 여기에 컨텐츠 너으면 댐~
            VStack(spacing: 20) {
                ForEach(0..<10) { i in
                    HStack {
                        ForEach(0..<10) { j in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.random)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text("\(i)-\(j)")
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.1))
    }
}

extension Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
