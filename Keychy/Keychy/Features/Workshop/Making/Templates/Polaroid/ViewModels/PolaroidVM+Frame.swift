//
//  PolaroidVM+Frame.swift
//  Keychy
//
//  프레임과 사진 합성 로직
//

import SwiftUI
import NukeUI
import Nuke

extension PolaroidVM {

    // MARK: - Frame Composition

    /// 선택한 사진과 프레임을 합성하여 bodyImage로 저장
    /// FramePreviewView에서 보이는 크기와 배치 그대로 저장
    func composePhotoWithFrame() async {
        guard let frame = selectedFrame,
              let frameURL = URL(string: frame.frameURL) else {
            return
        }

        // 합성 시작
        await MainActor.run {
            isComposingPhoto = true
        }

        defer {
            Task { @MainActor in
                isComposingPhoto = false
            }
        }

        // 프레임 이미지 다운로드
        guard let originalFrameImage = await downloadFrameImage(from: frameURL) else {
            return
        }

        // FramePreviewView와 동일한 크기로 합성
        let targetFrameHeight: CGFloat = 324  // FramePreviewView의 프레임 height
        let frameAspect = originalFrameImage.size.width / originalFrameImage.size.height
        let targetFrameWidth = targetFrameHeight * frameAspect
        let targetFrameSize = CGSize(width: targetFrameWidth, height: targetFrameHeight)

        // 사진이 없으면 프레임만 저장
        guard let photo = selectedPhotoImage else {
            let renderer = UIGraphicsImageRenderer(size: targetFrameSize)
            let frameOnlyImage = renderer.image { context in
                originalFrameImage.draw(in: CGRect(origin: .zero, size: targetFrameSize))
            }
            bodyImage = frameOnlyImage
            return
        }

        // 사진 영역 (FramePreviewView와 동일한 크기)
        let photoWidth: CGFloat = 214
        let photoHeight: CGFloat = 267
        let photoBottomPadding: CGFloat = 20  // FramePreviewView의 .padding(.bottom, 20)
        let photoOffsetX: CGFloat = 3  // FramePreviewView의 .offset(x: 3)

        // 사진을 프레임 중앙 하단에 배치 (하단에서 20pt 위, 중앙에서 3pt 오른쪽)
        let photoX = (targetFrameWidth - photoWidth) / 2 + photoOffsetX
        let photoY = targetFrameHeight - photoHeight - photoBottomPadding

        let photoRect = CGRect(x: photoX, y: photoY, width: photoWidth, height: photoHeight)

        let renderer = UIGraphicsImageRenderer(size: targetFrameSize)

        let composedImage = renderer.image { context in
            // 1. 사진 그리기 (배경)
            context.cgContext.saveGState()
            context.cgContext.addRect(photoRect)
            context.cgContext.clip()

            // 사진을 영역에 맞게 scaledToFill로 그리기
            let photoAspect = photo.size.width / photo.size.height
            let rectAspect = photoRect.width / photoRect.height

            var drawRect = photoRect
            if photoAspect > rectAspect {
                // 사진이 더 넓음 - 높이 기준으로 맞춤
                let scaledWidth = photoRect.height * photoAspect
                drawRect = CGRect(
                    x: photoRect.midX - scaledWidth / 2,
                    y: photoRect.minY,
                    width: scaledWidth,
                    height: photoRect.height
                )
            } else {
                // 사진이 더 높음 - 너비 기준으로 맞춤
                let scaledHeight = photoRect.width / photoAspect
                drawRect = CGRect(
                    x: photoRect.minX,
                    y: photoRect.midY - scaledHeight / 2,
                    width: photoRect.width,
                    height: scaledHeight
                )
            }

            // 사진 변환 적용 (확대/축소, 회전, 이동)
            let centerX = drawRect.midX
            let centerY = drawRect.midY

            // 변환의 중심점을 사진 중심으로 이동
            context.cgContext.translateBy(x: centerX, y: centerY)

            // 변환 적용 순서: offset -> rotation -> scale
            context.cgContext.translateBy(x: photoOffset.width, y: photoOffset.height)
            context.cgContext.rotate(by: CGFloat(photoRotation.radians))
            context.cgContext.scaleBy(x: photoScale, y: photoScale)

            // 이미지를 원점 중심으로 그리기
            let centeredRect = CGRect(
                x: -drawRect.width / 2,
                y: -drawRect.height / 2,
                width: drawRect.width,
                height: drawRect.height
            )
            photo.draw(in: centeredRect)
            context.cgContext.restoreGState()

            // 2. 프레임 이미지 그리기 (위에 오버레이, 리사이즈된 크기로)
            originalFrameImage.draw(in: CGRect(origin: .zero, size: targetFrameSize))
        }

        bodyImage = composedImage
    }

    // MARK: - Helper: Download Frame Image

    /// NukeUI를 사용하여 프레임 이미지 다운로드
    private func downloadFrameImage(from url: URL) async -> UIImage? {
        // Bundle에서 먼저 확인 (로컬 이미지인 경우)
        if url.scheme == nil || url.scheme == "file" {
            // 로컬 이미지 경로
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
