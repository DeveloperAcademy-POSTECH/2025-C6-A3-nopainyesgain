//
//  KeyringRingComponent.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/18/25.
//

import UIKit
import SpriteKit

// MARK: - Keyring Ring Component
struct KeyringRingComponent {

    // Ring 타입 받아서 SKSpriteNode로 생성
    static func createNode(from ringType: RingType) -> SKSpriteNode {
        switch ringType {
        case .basic:
            return createBasicRing()
        }
    }

    // MARK: - Basic Ring
    private static func createBasicRing() -> SKSpriteNode {
        let outerRadius: CGFloat = 50
        let innerRadius: CGFloat = 42
        let thickness = outerRadius - innerRadius
        let ringSize = outerRadius * 2 // 지름

        // 이미지로 스프라이트 노드 생성
        let node = SKSpriteNode(imageNamed: "basicRing")
        node.size = CGSize(width: ringSize, height: ringSize)

        // 물리 바디를 도넛 형태로 근사
        // 여러 개의 작은 원으로 도넛 형태를 만듦
        let segments = 32
        var bodies: [SKPhysicsBody] = []

        for i in 0..<segments {
            let angle = (CGFloat(i) / CGFloat(segments)) * .pi * 2
            let avgRadius = (outerRadius + innerRadius) / 2
            let x = cos(angle) * avgRadius
            let y = sin(angle) * avgRadius

            let segmentBody = SKPhysicsBody(circleOfRadius: thickness / 2, center: CGPoint(x: x, y: y))
            bodies.append(segmentBody)
        }

        let physicsBody = SKPhysicsBody(bodies: bodies)
        physicsBody.mass = 0.5
        physicsBody.friction = 0.4
        physicsBody.restitution = 0.3
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.8
        node.physicsBody = physicsBody

        return node
    }
}
