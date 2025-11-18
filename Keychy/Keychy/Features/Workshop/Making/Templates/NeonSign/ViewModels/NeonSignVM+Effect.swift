//
//  NeonSignVM+Effect.swift
//  Keychy
//
//  Created by Rundo on 11/8/25.
//

import Combine
import Foundation
import SwiftUI

extension NeonSignVM {

    /// 커스터마이징 모드 (네온 사인은 그리기 + 이펙트 지원, 이펙트가 마지막)
    var availableCustomizingModes: [CustomizingMode] {
        [.drawing, .effect]
    }

    // MARK: - View Providers (모드별 뷰 제공)

    /// 씬 뷰 제공 (모드별)
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
        case .drawing:
            return AnyView(DrawingCanvasView(viewModel: self))
        }
    }

    /// 하단 콘텐츠 뷰 제공 (모드별)
    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(EffectSelectorView(viewModel: self, cartItems: cartItems))
        case .drawing:
            return AnyView(DrawingToolsView(viewModel: self))
        }
    }

    /// 사운드 업데이트
    func updateSound(_ sound: Sound?) {
        selectedSound = sound
        soundId = sound?.id ?? "none"
        effectSubject.send((soundId, particleId, .sound))
    }

    /// 파티클 업데이트
    func updateParticle(_ particle: Particle?) {
        selectedParticle = particle
        particleId = particle?.id ?? "none"
        effectSubject.send((soundId, particleId, .particle))
    }

    // MARK: - Custom Sound (녹음)

    /// 커스텀 사운드 존재 여부
    var hasCustomSound: Bool {
        customSoundURL != nil
    }

    /// 커스텀 사운드 적용
    func applyCustomSound(_ url: URL) {
        customSoundURL = url

        // 기존 사운드 선택 해제
        selectedSound = nil

        // soundId를 특별한 값으로 설정 (나중에 재생 시 구분)
        soundId = "custom_recording"
        effectSubject.send((soundId, particleId, .sound))
    }

    /// 커스텀 사운드 제거
    func removeCustomSound() {
        customSoundURL = nil
        soundId = "none"
        effectSubject.send((soundId, particleId, .sound))
    }

    // MARK: - Ownership Check

    /// 사운드 소유 여부 확인 (Firebase 구매 기록)
    func isOwned(soundId: String) -> Bool {
        return EffectManager.shared.isOwned(soundId: soundId, userManager: userManager)
    }

    /// 파티클 소유 여부 확인 (Firebase 구매 기록)
    func isOwned(particleId: String) -> Bool {
        return EffectManager.shared.isOwned(particleId: particleId, userManager: userManager)
    }

    /// 사운드가 Bundle에 포함되어 있는지 (앱에 포함된 무료 아이템)
    func isInBundle(soundId: String) -> Bool {
        return EffectManager.shared.isInBundle(soundId: soundId)
    }

    /// 파티클이 Bundle에 포함되어 있는지 (앱에 포함된 무료 아이템)
    func isInBundle(particleId: String) -> Bool {
        return EffectManager.shared.isInBundle(particleId: particleId)
    }

    /// 사운드가 Cache에 다운로드되어 있는지
    func isInCache(soundId: String) -> Bool {
        return EffectManager.shared.isInCache(soundId: soundId)
    }

    /// 파티클이 Cache에 다운로드되어 있는지
    func isInCache(particleId: String) -> Bool {
        return EffectManager.shared.isInCache(particleId: particleId)
    }

    // MARK: - Drawing Composition

    /// 그림을 bodyImage와 합성
    func composeDrawingWithBodyImage() {
        guard let original = originalBodyImage, !drawingPaths.isEmpty else {
            // 그림이 없으면 원본으로 복원
            if let original = originalBodyImage {
                bodyImage = original
            }
            return
        }

        let imageSize = original.size
        let renderer = UIGraphicsImageRenderer(size: imageSize)

        // 화면 좌표 → 이미지 좌표 변환 비율 계산
        let scaleX = imageSize.width / imageFrame.width
        let scaleY = imageSize.height / imageFrame.height

        let composedImage = renderer.image { context in
            // 1. 원본 이미지 그리기
            original.draw(at: .zero)

            // 2. 그림 경로들 그리기
            let cgContext = context.cgContext

            for drawnPath in drawingPaths {
                // 화면 좌표의 Path를 이미지 좌표로 변환
                var transformedPath = Path()

                drawnPath.path.forEach { element in
                    switch element {
                    case .move(to: let point):
                        // imageFrame 기준으로 좌표 변환
                        let transformedPoint = CGPoint(
                            x: (point.x - imageFrame.origin.x) * scaleX,
                            y: (point.y - imageFrame.origin.y) * scaleY
                        )
                        transformedPath.move(to: transformedPoint)

                    case .line(to: let point):
                        let transformedPoint = CGPoint(
                            x: (point.x - imageFrame.origin.x) * scaleX,
                            y: (point.y - imageFrame.origin.y) * scaleY
                        )
                        transformedPath.addLine(to: transformedPoint)

                    case .quadCurve(to: let point, control: let control):
                        let transformedPoint = CGPoint(
                            x: (point.x - imageFrame.origin.x) * scaleX,
                            y: (point.y - imageFrame.origin.y) * scaleY
                        )
                        let transformedControl = CGPoint(
                            x: (control.x - imageFrame.origin.x) * scaleX,
                            y: (control.y - imageFrame.origin.y) * scaleY
                        )
                        transformedPath.addQuadCurve(to: transformedPoint, control: transformedControl)

                    case .curve(to: let point, control1: let control1, control2: let control2):
                        let transformedPoint = CGPoint(
                            x: (point.x - imageFrame.origin.x) * scaleX,
                            y: (point.y - imageFrame.origin.y) * scaleY
                        )
                        let transformedControl1 = CGPoint(
                            x: (control1.x - imageFrame.origin.x) * scaleX,
                            y: (control1.y - imageFrame.origin.y) * scaleY
                        )
                        let transformedControl2 = CGPoint(
                            x: (control2.x - imageFrame.origin.x) * scaleX,
                            y: (control2.y - imageFrame.origin.y) * scaleY
                        )
                        transformedPath.addCurve(to: transformedPoint, control1: transformedControl1, control2: transformedControl2)

                    case .closeSubpath:
                        transformedPath.closeSubpath()

                    @unknown default:
                        break
                    }
                }

                let cgPath = transformedPath.cgPath

                cgContext.setStrokeColor(UIColor(drawnPath.color).cgColor)
                cgContext.setLineWidth(drawnPath.lineWidth * scaleX)  // 선 굵기도 스케일링
                cgContext.setLineCap(.round)
                cgContext.setLineJoin(.round)

                cgContext.addPath(cgPath)
                cgContext.strokePath()
            }
        }

        // 합성된 이미지를 bodyImage에 저장
        bodyImage = composedImage
    }

    // MARK: - Reset (그리기 상태 포함)

    /// 커스터마이징 데이터 초기화 (이펙트 + 그리기)
    func resetCustomizingData() {
        // 기본 이펙트 초기화
        selectedSound = nil
        selectedParticle = nil
        customSoundURL = nil
        soundId = "none"
        particleId = "none"
        downloadingItemIds.removeAll()
        downloadProgress.removeAll()

        // 그리기 상태 초기화
        drawingPaths.removeAll()
        currentDrawingColor = .white
        currentLineWidth = 3.0

        // 원본 이미지로 복원
        if let original = originalBodyImage {
            bodyImage = original
        }
    }

    // MARK: - Download (EffectManager 위임)

    /// 사운드 다운로드
    func downloadSound(_ sound: Sound) async {
        guard let soundId = sound.id else { return }

        // ViewModel 상태 시작
        await MainActor.run {
            downloadingItemIds.insert(soundId)
            downloadProgress[soundId] = 0.0
        }

        // Progress 모니터링 Task
        let monitorTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    // EffectManager의 progress를 ViewModel에 복사
                    if let progress = EffectManager.shared.downloadProgress[soundId] {
                        downloadProgress[soundId] = progress
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초마다 확인
            }
        }

        // EffectManager를 통해 다운로드
        await EffectManager.shared.downloadSound(sound, userManager: userManager)

        // 모니터링 중단
        monitorTask.cancel()

        // 다운로드 완료 후 상태 정리 및 자동 선택
        await MainActor.run {
            downloadingItemIds.remove(soundId)
            downloadProgress.removeValue(forKey: soundId)
            updateSound(sound)
        }
    }

    /// 파티클 다운로드
    func downloadParticle(_ particle: Particle) async {
        guard let particleId = particle.id else { return }

        // ViewModel 상태 시작
        await MainActor.run {
            downloadingItemIds.insert(particleId)
            downloadProgress[particleId] = 0.0
        }

        // Progress 모니터링 Task
        let monitorTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    // EffectManager의 progress를 ViewModel에 복사
                    if let progress = EffectManager.shared.downloadProgress[particleId] {
                        downloadProgress[particleId] = progress
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초마다 확인
            }
        }

        // EffectManager를 통해 다운로드
        await EffectManager.shared.downloadParticle(particle, userManager: userManager)

        // 모니터링 중단
        monitorTask.cancel()

        // 다운로드 완료 후 상태 정리 및 자동 선택
        await MainActor.run {
            downloadingItemIds.remove(particleId)
            downloadProgress.removeValue(forKey: particleId)
            updateParticle(particle)
        }
    }
}
