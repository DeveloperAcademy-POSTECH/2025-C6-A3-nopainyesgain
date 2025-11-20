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
            }
        }
    }
}

// MARK: - Nuke Animated Image View (GIF 지원)
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
        guard let url = url else {
            uiView.image = nil
            isLoading = false
            return
        }

        isLoading = true

        // Nuke로 이미지 로드 (GIF 애니메이션 지원)
        ImagePipeline.shared.loadImage(with: url) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let response):
                    // GIF인 경우 애니메이션 이미지로 표시
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
}

// MARK: - UIImage GIF Extension
extension UIImage {
    /// GIF 데이터에서 애니메이션 이미지 생성
    static func animatedImage(with data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: TimeInterval = 0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                // 프레임 지속 시간 가져오기
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let frameDuration = gifInfo[kCGImagePropertyGIFDelayTime as String] as? TimeInterval {
                    duration += frameDuration
                } else {
                    duration += 0.1 // 기본 프레임 지속 시간
                }

                images.append(UIImage(cgImage: cgImage))
            }
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ItemDetailImage(itemURL: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24")
}
