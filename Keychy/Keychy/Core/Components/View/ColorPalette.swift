//
//  ColorPalette.swift
//  Keychy
//
//  Created by 길지훈 on 11/24/25.
//
//  재사용 가능한 색상 선택 팔레트 컴포넌트
//

import SwiftUI

struct ColorPalette: View {
    @Binding var selectedColor: Color

    /// 프리셋 색상들
    private let presetColors: [Color] = [
        .black,
        .white,
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        Color(red: 0, green: 0, blue: 0.5), // Navy
        .purple
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 11) {
                // ColorPicker
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .frame(width: 37, height: 37)

                // 프리셋 색상들
                ForEach(presetColors, id: \.self) { color in
                    Button {
                        selectedColor = color
                        Haptic.impact(style: .light)
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 37, height: 37)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .shadow(color: selectedColor == color ? Color.black.opacity(0.5) : Color.clear, radius: 2)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    @Previewable @State var selectedColor: Color = .black

    VStack {
        ColorPalette(selectedColor: $selectedColor)
            .background(Color.gray50)

        Text("선택된 색상")
            .foregroundStyle(selectedColor)
    }
}
