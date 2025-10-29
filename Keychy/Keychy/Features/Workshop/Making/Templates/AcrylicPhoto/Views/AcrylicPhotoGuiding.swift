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
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 닫기 버튼
            HStack {
                backBtn
                    .padding(.top, 30.5)
                    .padding(.leading, 20)
                Spacer()
            }
            .padding(.bottom, 19.5)
            
            guidingIcon
                .padding(.bottom, 8)
            
            guidingTextLabel
                .padding(.bottom, 22)
            
            guidingImage
                .padding(.bottom, 23)
            
            // 카메라/사진선택 버튼
            HStack(spacing: 12) {
                cameraBtn
                photoPickBtn
            }
            .padding(.horizontal, 35)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Components
extension AcrylicPhotoGuiding {
    private var backBtn: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 24))
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
            Image(systemName: "camera.fill")
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .frame(width: 50, height: 48)
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
            HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 15))
                Text("사진 선택")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.vertical, 15)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
        }
    }
    
    private var guidingIcon: some View {
        Image(.fireworks)
            .resizable()
            .frame(width: 32, height: 32)
    }
    
    private var guidingTextLabel: some View {
        Text(guidingText)
            .typography(.suit20B)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
    
    private var guidingImage: some View {
        LazyImage(url: URL(string: guidingImageURL)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Color.gray.opacity(0.1)
            }
        }
        .frame(maxWidth: .infinity)
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
