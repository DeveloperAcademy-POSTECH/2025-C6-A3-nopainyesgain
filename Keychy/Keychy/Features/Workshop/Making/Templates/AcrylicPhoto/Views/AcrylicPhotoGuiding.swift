//
//  AcrylicPhotoGuiding.swift
//  Keychy
//
//  Created by Claude on 10/29/25.
//

import SwiftUI
import NukeUI

struct AcrylicPhotoGuiding: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showPhotoPicker: Bool
    @Binding var showCamera: Bool
    let guidingText: String
    let guidingImageURL: String

    @State private var contentHeight: CGFloat = 500

    var body: some View {
        VStack(spacing: 0) {
            // 상단 닫기 버튼
            HStack {
                backBtn
                    .padding(.top, 30)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.bottom, 19.5)
            
            guidingTextLabel
                .padding(.bottom, 5)
            
            Text("배경은 자동으로 지워져요.")
                .typography(.suit16B)
                .padding(.bottom, 38)
            
            guidingImage
                .padding(.bottom, 23)
            
            // 카메라/사진선택 버튼
            HStack(spacing: 12) {
                cameraBtn
                photoPickBtn
            }
            .padding(.horizontal, 35)
        }
        .background(
            GeometryReader { geometry in
                Color.white100.preference(
                    key: GuidingHeightPreferenceKey.self,
                    value: geometry.size.height
                )
                .ignoresSafeArea()
            }
        )
        .onPreferenceChange(GuidingHeightPreferenceKey.self) { height in
            if height > 0 {
                contentHeight = height
            }
        }
        .presentationDetents([.height(contentHeight)])
    }
}

// MARK: - PreferenceKey
struct GuidingHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 500
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Components
extension AcrylicPhotoGuiding {
    private var backBtn: some View {
        Button {
            dismiss()
        } label: {
            Image("dismiss")
                .foregroundStyle(.primary)
        }
    }
    
    private var cameraBtn: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCamera = true
            }
        } label: {
            Image("camera")
                .foregroundStyle(.secondary)
                //.frame(width: 36, height: 36)
        }
        .buttonStyle(.glass)
        .clipShape(Circle())
    }
    
    private var photoPickBtn: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showPhotoPicker = true
            }
        } label: {
            HStack(spacing: 2) {
                Image("pic")
                Text("사진 선택")
                    .typography(.suit17B)
                    .padding(.vertical, 15)
            }
            .foregroundStyle(.white100)
            .frame(maxWidth: .infinity)
            .background(.gray700)
            .clipShape(Capsule())
        }
    }
    
    private var guidingTextLabel: some View {
        
        Text(guidingText)
            .typography(.suit20B)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
    
    private var guidingImage: some View {
        Image("acrylicGudingImage")
            .resizable()
            .scaledToFit()
            .frame(minHeight: 272.87)
            .padding(.horizontal, 30)
    }
}

#Preview {
    AcrylicPhotoGuiding(
        showPhotoPicker: .constant(false),
        showCamera: .constant(false),
        guidingText: "인물 사진을 선택해주세요\n배경이 제거된 키링을 만들 수 있습니다",
        guidingImageURL: ""
    )
}
