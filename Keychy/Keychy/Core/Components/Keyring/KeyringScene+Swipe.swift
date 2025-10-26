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
}
