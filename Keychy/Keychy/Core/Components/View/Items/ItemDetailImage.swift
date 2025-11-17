//
//  TemplateItemDetailImage.swift
//  Keychy
//
//  Created by 길지훈 on 10/28/25.
//

import SwiftUI
import NukeUI

struct ItemDetailImage: View {
    
    /// 파이어 스토어에서 가져올 item이미지
    let itemURL: String
    
    var body: some View {
        LazyImage(url: URL(string: itemURL)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if state.isLoading {
                LoadingAlert(type: .short, message: nil)
                    .scaleEffect(0.5)
            } else {
                Color.gray.opacity(0.1)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ItemDetailImage(itemURL: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24")
}
