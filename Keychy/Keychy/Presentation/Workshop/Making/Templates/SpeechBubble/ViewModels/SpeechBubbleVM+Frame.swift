//
//  SpeechBubbleVM+Frame.swift
//  Keychy
//
//  Created by 길지훈 on 11/23/25.
//

import SwiftUI
import Nuke

extension SpeechBubbleVM {

    // MARK: - Frame Composition

    /// 입력한 텍스트와 프레임을 합성하여 bodyImage로 저장
    func composeTextWithFrame() async {
        guard let frame = selectedFrame,
              let frameURL = URL(string: frame.frameURL) else {
            return
        }

        // 합성 시작 (로딩 표시)
        await MainActor.run {
            isComposingText = true
        }

        defer {
            Task { @MainActor in
                isComposingText = false
            }
        }

        // 프레임 이미지 다운로드
        guard let originalFrameImage = await downloadFrameImage(from: frameURL) else {
            return
        }

        // 프레임 크기 조정
        let targetFrameHeight: CGFloat = 324  // 폴라로이드와 동일한 크기
        let frameAspect = originalFrameImage.size.width / originalFrameImage.size.height
        let targetFrameWidth = targetFrameHeight * frameAspect
        let targetFrameSize = CGSize(width: targetFrameWidth, height: targetFrameHeight)

        let renderer = UIGraphicsImageRenderer(size: targetFrameSize)

        let composedImage = renderer.image { context in
            // 1. 프레임 이미지 그리기 (배경)
            originalFrameImage.draw(in: CGRect(origin: .zero, size: targetFrameSize))

            // 2. 텍스트 그리기 (중앙 + textOffsetY)
            if !inputText.isEmpty {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                paragraphStyle.lineSpacing = 3

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "GulimChe", size: 30) ?? UIFont.systemFont(ofSize: 30),
                    .foregroundColor: UIColor(selectedTextColor),
                    .paragraphStyle: paragraphStyle
                ]

                let attributedString = NSAttributedString(string: inputText, attributes: attributes)
                let textSize = attributedString.boundingRect(
                    with: CGSize(width: targetFrameSize.width - 40, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).size

                // 텍스트 위치 (중앙 + textOffsetY + 보정값)
                let textX = (targetFrameSize.width - textSize.width) / 2
                let lineCount = inputText.components(separatedBy: "\n").count
                let verticalOffset: CGFloat = lineCount > 1 ? 3 : 0  // 여러 줄일 때만 3pt 아래로 보정
                let baseCenterY = (targetFrameSize.height - textSize.height) / 2
                let offsetY = frame.textOffsetY ?? 0
                let textY = baseCenterY + offsetY + verticalOffset

                let textRect = CGRect(
                    x: textX,
                    y: textY,
                    width: textSize.width,
                    height: textSize.height
                )

                attributedString.draw(in: textRect)
            }
        }

        bodyImage = composedImage
    }

    // MARK: - Helper: Download Frame Image

    /// Nuke를 사용하여 프레임 이미지 다운로드
    private func downloadFrameImage(from url: URL) async -> UIImage? {
        // Bundle에서 먼저 확인 (로컬 이미지인 경우)
        if url.scheme == nil || url.scheme == "file" {
            let imageName = url.lastPathComponent.replacingOccurrences(of: ".png", with: "")
            return UIImage(named: imageName)
        }

        // 원격 이미지 다운로드
        return await withCheckedContinuation { continuation in
            Task {
                do {
                    let imageRequest = ImageRequest(url: url)
                    let response = try await ImagePipeline.shared.image(for: imageRequest)
                    continuation.resume(returning: response)
                } catch {
                    print("Failed to download frame image: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
