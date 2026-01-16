//
//  BundleViewModel+CaptureScene.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

import SwiftUI

extension BundleViewModel {
    /// 캡쳐한 씬을 보여주는 메서드
    ///
    // BundleNameInputView, BundleNameEditView에서 사용하는 미리보기 씬
    @ViewBuilder
    func bundleCaptureSceneView() -> some View {
        let widthSize = screenWidth - 176
        let heightSize = widthSize * 7/5
        
        Group {
            if let imageData = bundleCapturedImage,
               let uiImage = UIImage(data: imageData) {
                // 캡처된 이미지 표시
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .offset(y: 30)
                    .clipped()
            } else {
                // 이미지가 없으면 기본 메시지 표시
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("이미지를 불러오는 중...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: widthSize, height: heightSize)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .clipped()
    }
}
