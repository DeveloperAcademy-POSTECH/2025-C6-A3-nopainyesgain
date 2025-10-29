//
//  TemplatePreviewImage.swift
//  Keychy
//
//  Created by 길지훈 on 10/28/25.
//

import SwiftUI
import NukeUI

struct PreviewImage: View {
    
    /// 파이어 스토어에서 가져올 프리뷰이미지
    let previewURL: String
    
    var body: some View {
        LazyImage(url: URL(string: previewURL)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if state.isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.1)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PreviewImage(previewURL: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24")
}
