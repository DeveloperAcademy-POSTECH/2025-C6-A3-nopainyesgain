//
//  KeyringChainComponent.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/18/25.
//

import UIKit
import SpriteKit

// MARK: - Keyring Chain Component
struct KeyringChainComponent {

    // Chain 타입 받아서 링크들을 생성
    static func createLinks(
        from chainType: ChainType,
        count: Int,
        startPosition: CGPoint,
        spacing: CGFloat
    ) -> [SKSpriteNode] {
        switch chainType {
        case .basic:
            return createBasicChainLinks(count: count, startPosition: startPosition, spacing: spacing)
        }
    }

    // MARK: - Basic Chain Links
    private static func createBasicChainLinks(
        count: Int,
        startPosition: CGPoint,
        spacing: CGFloat
    ) -> [SKSpriteNode] {
        var links: [SKSpriteNode] = []

        for i in 0..<count {
            let width = (i % 2 == 0) ? 5.0 : 18.0
            let height = (i % 2 == 0) ? 22.0 : 26.0
            let imageName = (i % 2 == 0) ? "basicChain1" : "basicChain2"

            let node = SKSpriteNode(imageNamed: imageName)
            node.size = CGSize(width: width, height: height)
            node.position = CGPoint(
                x: startPosition.x,
                y: startPosition.y - CGFloat(i) * spacing
            )
            node.zPosition = (i % 2 == 0) ? 1 : 0 // 짝수번째 노드가 위에 보이도록 처리

            let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width - 4, height: height - 4))
            physicsBody.mass = 2.0
            physicsBody.friction = 0.4
            physicsBody.restitution = 0.3
            physicsBody.linearDamping = 0.5
            physicsBody.angularDamping = 0.8
            node.physicsBody = physicsBody

            links.append(node)
        }

        return links
    }

    // MARK: - Chain Link Shape
    private static func createChainLink(width: CGFloat, height: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let radius = width / 2
        let innerWidth = width - 6
        let innerHeight = height - 8

        let outerRect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        path.addRoundedRect(in: outerRect, cornerWidth: radius, cornerHeight: radius)

        let innerRect = CGRect(x: -innerWidth / 2, y: -innerHeight / 2, width: innerWidth, height: innerHeight)
        path.addRoundedRect(in: innerRect, cornerWidth: innerWidth / 2, cornerHeight: innerWidth / 2)

        let node = SKShapeNode(path: path, centered: true)
        node.fillColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        node.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        node.lineWidth = 0.5

        return node
    }
}
