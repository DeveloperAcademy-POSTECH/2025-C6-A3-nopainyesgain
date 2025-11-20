//
//  LottieView.swift
//  KeytschPrototype
//
//  Created by rundo on 10/21/25.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let speed: CGFloat

    private let animationView = LottieAnimationView()

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        // particleId로 캐시 → Bundle 순서로 파일 찾기
        if let animation = findParticleAnimation(particleId: name) {
            animationView.animation = animation
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = loopMode
            animationView.animationSpeed = speed
            animationView.play()
        } else {
            // 파티클을 찾을 수 없을 때
            print("[LottieView] 파티클 찾을 수 없음: \(name)")
        }

        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    /// 파티클 애니메이션 파일 찾기 (캐시 → Bundle 순서)
    private func findParticleAnimation(particleId: String) -> LottieAnimation? {
        // 1. 로컬 캐시에서 찾기
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")

        if FileManager.default.fileExists(atPath: cachedURL.path) {
            return LottieAnimation.filepath(cachedURL.path)
        }

        // 2. Bundle에서 찾기 (기본 무료 파티클)
        if let animation = LottieAnimation.named(particleId) {
            return animation
        }

        return nil
    }
}
