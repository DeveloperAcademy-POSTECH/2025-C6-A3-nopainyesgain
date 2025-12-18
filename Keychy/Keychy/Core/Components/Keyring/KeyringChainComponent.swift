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
        carabinerType: CarabinerType? = nil,
        baseZPosition: CGFloat = 0,
        completion: @escaping ([SKSpriteNode]) -> Void
    ) {
        
        let chainLinks = chainType.createChainLinks(length: count, for: carabinerType)
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
                            index: index,
                            carabinerType: carabinerType,
                            baseZPosition: baseZPosition
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

            completion(nodes)
        }
    }

    // MARK: - 단일 체인 링크 노드 생성
    // UIImage와 링크 정보로 SKSpriteNode 생성
    static func createChainLinkNode(
        image: UIImage,
        link: ChainType.ChainLink,
        position: CGPoint,
        index: Int,
        carabinerType: CarabinerType? = nil,
        baseZPosition: CGFloat = 0
    ) -> SKSpriteNode {
        let texture = SKTexture(image: image)

        let node = SKSpriteNode(texture: texture)
        node.size = link.size
        node.position = position

        // 좁은 체인(width 5)이 넓은 체인(width 18)보다 항상 위에 쌓이도록
        let isNarrowChain = link.width < 10  // 좁은 체인 판별
        let narrowChainOffset: CGFloat = isNarrowChain ? 0.5 : 0.0

        // 카라비너 타입에 따라 zPosition 조정
        if let carabinerType = carabinerType, carabinerType == .plain {
            // Plain: 체인이 링 뒤로 가도록 (Ring이 baseZPosition이면 체인은 더 낮게)
            node.zPosition = baseZPosition - 1 - CGFloat(index) * 0.1 + narrowChainOffset
        } else {
            // Hamburger: 체인이 링 앞으로 (기존 방식)
            node.zPosition = baseZPosition + 2 + CGFloat(index) * 0.1 + narrowChainOffset
        }
        
        // 물리 바디 추가 (기본값으로 설정, 씬에서 조정됨)
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: link.width - 4, height: link.height - 4))
        physicsBody.isDynamic = true  // 기본값은 움직이게 설정, 나중에 씬에서 조정
        physicsBody.affectedByGravity = true  // 기본값은 중력 적용, 나중에 씬에서 조정
        physicsBody.mass = 2.0
        physicsBody.friction = 0.4
        physicsBody.restitution = 0.3
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.8
        node.physicsBody = physicsBody
        
        return node
    }
}
