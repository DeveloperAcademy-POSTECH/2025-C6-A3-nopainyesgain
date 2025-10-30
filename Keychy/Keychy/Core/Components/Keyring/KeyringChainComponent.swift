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

    static func createLinks(
        from chainType: ChainType,
        count: Int,
        startPosition: CGPoint,
        spacing: CGFloat,
        completion: @escaping ([SKSpriteNode]) -> Void
    ) {
        
        let chainLinks = chainType.createChainLinks(length: count)
        var nodesDictionary: [Int: SKSpriteNode] = [:]
        let group = DispatchGroup()
        
        for (index, link) in chainLinks.enumerated() {
            group.enter()
            
            // StorageManager로 이미지 다운
            Task {
                do {
                    let image = try await StorageManager.shared.getImage(path: link.imageURL)
                    
                    await MainActor.run {
                        let yPosition = startPosition.y - CGFloat(index) * spacing
                        
                        let node = createChainLinkNode(
                            image: image,
                            link: link,
                            position: CGPoint(x: startPosition.x, y: yPosition),
                            index: index
                        )
                        
                        nodesDictionary[index] = node
                        
                        group.leave()
                    }
                } catch {
                    await MainActor.run {
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            let nodes = (0..<count).compactMap { nodesDictionary[$0] }
            
            for (index, node) in nodes.enumerated() {
                print("   링크 \(index): position = (\(node.position.x), \(node.position.y))")
            }
            
            completion(nodes)
        }
    }

    // MARK: - 단일 체인 링크 노드 생성
    // UIImage와 링크 정보로 SKSpriteNode 생성
    private static func createChainLinkNode(
        image: UIImage,
        link: ChainType.ChainLink,
        position: CGPoint,
        index: Int
    ) -> SKSpriteNode {
        let texture = SKTexture(image: image)
        
        let node = SKSpriteNode(texture: texture)
        node.size = link.size
        node.position = position
        node.zPosition = (index % 2 == 0) ? 1 : 0 // 짝수번째 노드가 위에 보이도록
        
        // 물리 바디 추가
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: link.width - 4, height: link.height - 4))
        physicsBody.mass = 2.0
        physicsBody.friction = 0.4
        physicsBody.restitution = 0.3
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.8
        node.physicsBody = physicsBody
        
        return node
    }
}
