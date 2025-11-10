//
//  KeyringScene+Swipe.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/18/25.
//

import SpriteKit

// MARK: - Swipe Gesture Handling
extension KeyringScene {

    // Chain과 Body에 스와이프 영향 적용 (바디 중앙 기준 좌우 스와이프)
    func applySwipeForceToNearbyChains(at location: CGPoint, velocity: CGVector) {
        guard let body = bodyNode else { return }

        _ = body.position.x

        let forceMagnitude: CGFloat = 0.3

        // 체인에 힘 적용
        for chainNode in chainNodes {
            // 바디 중앙 기준으로 스와이프 방향에 따라 힘 적용
            let force = CGVector(
                dx: velocity.dx * forceMagnitude * 0.3,
                dy: velocity.dy * forceMagnitude * 0.3
            )

            chainNode.physicsBody?.applyImpulse(force)
        }

        // Body에도 힘 적용
        let bodyForce = CGVector(
            dx: velocity.dx * forceMagnitude * 0.5,
            dy: velocity.dy * forceMagnitude * 0.5
        )

        body.physicsBody?.applyImpulse(bodyForce)
    }

    // 씬 로딩 완료 시 자동으로 힘을 가해서 파티클 효과 발생 (환영 효과)
    func applyWelcomeImpulse() {
        guard bodyNode != nil else { return }

        // 파티클이 터질 정도의 속도 (speed > 1250)
        let welcomeVelocity = CGVector(dx: 2000, dy: 0)

        // 중앙 위치에서 스와이프 시뮬레이션
        let centerLocation = CGPoint(x: size.width / 3, y: size.height / 2)
        applySwipeForceToNearbyChains(at: centerLocation, velocity: welcomeVelocity)

        // 파티클 효과 발생
        applyParticleEffect(particleId: currentParticleId)
    }
}
