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
    static func createNode(
        from ringType: RingType,
        completion: @escaping (SKSpriteNode?) -> Void
    ) {
        // StorageManager로 이미지 다운
        Task {
            do {
                let image = try await StorageManager.shared.getImage(path: ringType.imageURL)
                
                await MainActor.run {
                    let node = createRingNode(
                        image: image,
                        ringType: ringType
                    )
                    
                    completion(node)
                }
            } catch {
                print("링 이미지 로드 실패: \(error)")
                
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Ring 노드 생성
    // UIImage와 RingType으로 SKSpriteNode 생성
    private static func createRingNode(
        image: UIImage,
        ringType: RingType
    ) -> SKSpriteNode {
        let ringSize = ringType.size
        let outerRadius = ringSize / 2
        let innerRadius = outerRadius * 0.84 // 비율은 추후 고리가 더 추가되면 따로 설정할 가능성 높음
        let thickness = outerRadius - innerRadius
        
        // 이미지로 스프라이트 노드 생성
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture)
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
        // 물리 시뮬레이션 설정 분기 처리
        physicsBody.isDynamic = true  // 기본값은 움직이게 설정
        physicsBody.affectedByGravity = true  // 기본값은 중력 적용
        physicsBody.mass = 0.5
        physicsBody.friction = 0.4
        physicsBody.restitution = 0.3
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.8
        node.physicsBody = physicsBody

        return node
    }
}
