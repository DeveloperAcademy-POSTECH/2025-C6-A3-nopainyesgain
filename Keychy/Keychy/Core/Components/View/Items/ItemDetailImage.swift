//
//  TemplateItemDetailImage.swift
//  Keychy
//
//  Created by 길지훈 on 10/28/25.
//

import SwiftUI
import NukeUI
import Nuke

struct ItemDetailImage: View {

    /// 파이어 스토어에서 가져올 item이미지
    let itemURL: String

    @State private var isLoading = true

    var body: some View {
        ZStack {
            // GIF 애니메이션을 지원하는 이미지 뷰
            NukeAnimatedImageView(url: URL(string: itemURL), isLoading: $isLoading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 로딩 중앙 배치
            if isLoading {
                LoadingAlert(type: .short, message: nil)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
            }
        }
    }
}

// MARK: - Nuke Animated Image View
struct NukeAnimatedImageView: UIViewRepresentable {
    let url: URL?
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        // Auto Layout 비활성화 (SwiftUI가 레이아웃 관리)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // URL이 변경되었는지 확인 (불필요한 재로드 방지)
        if context.coordinator.currentURL == url {
            return
        }

        context.coordinator.currentURL = url

        guard let url = url else {
            uiView.image = nil
            DispatchQueue.main.async {
                isLoading = false
            }
            return
        }

        DispatchQueue.main.async {
            isLoading = true
        }

        // 원본 데이터로 로드 (커스텀 GIF 파싱에서 다운샘플링)
        ImagePipeline.shared.loadImage(with: url) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let response):
                    // GIF인 경우 애니메이션 처리 (다운샘플링 포함)
                    if let data = response.container.data,
                       let animatedImage = UIImage.animatedImage(with: data) {
                        uiView.image = animatedImage
                    } else {
                        uiView.image = response.image
                    }
                case .failure:
                    uiView.image = nil
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var currentURL: URL?
    }
}

// MARK: - UIImage GIF Extension
extension UIImage {
    static func animatedImage(with data: Data, maxSize: CGSize = CGSize(width: 1200, height: 1200)) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)

        var images: [UIImage] = []
        var duration: TimeInterval = 0

        for i in 0..<count {
            // 다운샘플링 옵션 설정
            let options: [CFString: Any] = [
                kCGImageSourceThumbnailMaxPixelSize: max(maxSize.width, maxSize.height),
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCache: false
            ]

            if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, i, options as CFDictionary) {
                // 프레임 지속 시간 가져오기
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let frameDuration = gifInfo[kCGImagePropertyGIFDelayTime as String] as? TimeInterval {
                    duration += frameDuration
                } else {
                    duration += 0.1
                }

                images.append(UIImage(cgImage: cgImage))
            }
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }
}

// MARK: - Simple Animated Image (재사용 가능)
/// LazyImage를 GIF 지원 버전으로 대체할 수 있는 간단한 뷰
struct SimpleAnimatedImage: View {
    let url: String
    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            if loadFailed {
                Color.gray50
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray300)
                    }
            } else {
                NukeAnimatedImageView(url: URL(string: url), isLoading: $isLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ImageLoadFailed"))) { _ in
                        loadFailed = true
                    }

                if isLoading {
                    Color.gray50
                        .overlay {
                            LoadingAlert(type: .short, message: nil)
                                .scaleEffect(0.5)
                        }
                }
            }
        }
    }
}
