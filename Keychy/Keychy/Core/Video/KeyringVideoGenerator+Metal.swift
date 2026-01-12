//
//  KeyringVideoGenerator+Metal.swift
//  Keychy
//
//  Created by 길지훈 on 1/12/26.
//

import Foundation
import Metal
import MetalKit
import CoreVideo

// MARK: - Metal Utilities

extension KeyringVideoGenerator {

    /// CVPixelBuffer 생성
    /// Metal과 호환되는 BGRA 포맷의 PixelBuffer 생성
    func createPixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess else {
            return nil
        }

        return pixelBuffer
    }

    /// Metal RenderPassDescriptor 생성
    /// PixelBuffer를 Metal Texture로 변환하여 렌더링 준비
    func createRenderPassDescriptor(for pixelBuffer: CVPixelBuffer) -> MTLRenderPassDescriptor {
        guard metalDevice != nil else {
            fatalError("Metal device not available")
        }

        // CVPixelBuffer → MTLTexture 변환
        let textureCache = createTextureCache()
        var textureRef: CVMetalTexture?

        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &textureRef
        )

        guard let texture = textureRef.flatMap({ CVMetalTextureGetTexture($0) }) else {
            fatalError("Failed to create texture from pixel buffer")
        }

        // RenderPassDescriptor 설정
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        descriptor.colorAttachments[0].storeAction = .store

        return descriptor
    }

    /// Metal Texture Cache 생성
    /// PixelBuffer를 Metal Texture로 변환하기 위한 캐시
    func createTextureCache() -> CVMetalTextureCache {
        guard let metalDevice = metalDevice else {
            fatalError("Metal device not available")
        }

        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            metalDevice,
            nil,
            &textureCache
        )

        return textureCache!
    }
}
