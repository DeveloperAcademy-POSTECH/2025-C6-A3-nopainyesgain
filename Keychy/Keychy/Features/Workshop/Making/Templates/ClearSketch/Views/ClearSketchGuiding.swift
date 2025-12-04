//
//  ClearSketchGuiding.swift
//  Keychy
//
//  Created by Jini on 11/24/25.
//

import SwiftUI
import NukeUI

struct ClearSketchGuiding: View {
    @Environment(\.dismiss) var dismiss
    let guidingText: String
    let guidingImageURL: String

    @State private var contentHeight = screenHeight * 0.5

    var body: some View {
        VStack(spacing: 0) {
            // 상단 닫기 버튼
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(.dismissGray600)
                }
                .padding(.top, 30)
                .padding(.leading, 20)
                Spacer()
            }
            .padding(.bottom, 19.5)
            
            guidingTextLabel
                .padding(.bottom, 28)
            
            guidingImage
                .padding(.bottom, 23)
                .adaptiveBottomPadding()
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: GuidingHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        )
        .background(Color.white100) // VStack 전체 배경
        .presentationBackground(Color.white100) // 시트 배경 (위로 땡겨도 하얀색)
        .onPreferenceChange(GuidingHeightPreferenceKey.self) { height in
            if height > 0 {
                contentHeight = height
            }
        }
        .presentationDetents([.height(contentHeight)])
    }
}

// MARK: - Components
extension ClearSketchGuiding {
    private var guidingTextLabel: some View {
        Text(guidingText)
            .typography(.suit20B)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
    
    private var guidingImage: some View {
        Image(.clearSketchGuiding)
            .resizable()
            .scaledToFit()
            .frame(minHeight: 272.87)
            .padding(.horizontal, 30)
    }
}
