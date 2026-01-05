//
//  AnimatedGIFView.swift
//  Keychy
//
//  Created by 길지훈 on 1/5/26.
//
//  GIF 애니메이션 뷰 (로컬/원격 지원)
//

import SwiftUI

// MARK: - GIF Source
enum GIFSource {
    case local(String)      // Bundle 에셋 이름
    case remote(URL)        // 원격 URL
}

// MARK: - Animated GIF View
struct AnimatedGIFView: View {
    let source: GIFSource
    let size: CGSize
    var opacity: Double = 1.0  // 기본값 1.0

    var body: some View {
        switch source {
        case .local(let name):
            LocalGIFView(gifName: name, opacity: opacity)
                .frame(width: size.width, height: size.height)

        case .remote(let url):
            RemoteGIFView(url: url, size: size, opacity: opacity)
        }
    }
}

// MARK: - Local GIF View
private struct LocalGIFView: UIViewRepresentable {
    let gifName: String
    let opacity: Double

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.alpha = opacity

        // Content Hugging & Compression Resistance Priority 설정
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        if let asset = NSDataAsset(name: gifName),
           let animatedImage = UIImage.animatedImage(with: asset.data, maxSize: CGSize(width: 2000, height: 2000)) {
            imageView.image = animatedImage
        }

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.alpha = opacity
    }
}

// MARK: - Remote GIF View
private struct RemoteGIFView: View {
    let url: URL
    let size: CGSize
    let opacity: Double

    @State private var isLoading = false

    var body: some View {
        NukeAnimatedImageView(
            url: url,
            isLoading: $isLoading,
            maxSize: CGSize(width: 2000, height: 2000)
        )
        .frame(width: size.width, height: size.height)
        .opacity(opacity)
    }
}
