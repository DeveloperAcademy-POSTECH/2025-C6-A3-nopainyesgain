//
//  BundleRingComponent.swift
//  Keychy
//
//  Created by 김서현 on 11/9/25.
//

import UIKit
import SpriteKit

// MARK: - Keyring Ring Component
struct BundleRingComponent{
    
    //Carabiner Type 받아서 SkSpriteNode로 Ring 생성
    // Carabiner Type에 따른 분기처리
    static func createCarabinerRingNode(
        carabinerType: CarabinerType,
        ringType: RingType,
        completion: @escaping (SKSpriteNode?) -> Void
    ) {
        // StorageManager로 이미지 다운
        Task {
            do {
                let image = try await StorageManager.shared.getImage(path: (carabinerType == .plain ? ringType.sideImageURL : ringType.imageURL))
                await MainActor.run {
                    let node = (carabinerType == .plain ? createPlainRingNode(image: image, ringType: ringType) : createHamburgerRingNode(image: image, ringType: ringType))
                    completion(node)
                }
            } catch {
                print("링 이미지 로드 실패 : \(error)")
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
    
    //MARK: - 햄버거 타입 카라비너의 ring 노드 생성
    // UIImage와 RingType으로 SKspriteNode 생성
    // 카라비너 타입에 따른 분기처리
    private static func createHamburgerRingNode(
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
        physicsBody.mass = 0.5
        physicsBody.friction = 0.4
        physicsBody.restitution = 0.3
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.8
        node.physicsBody = physicsBody

        return node
    }
    
    //MARK: - plain 타입 카라비너의 ring 노드 생성
    // plain 카라비너의 ring은 노드가 한 군데만 고정되면 되기 때문에 다른 물리속성들은 설정 x
    private static func createPlainRingNode(
        image: UIImage,
        ringType: RingType
    ) -> SKSpriteNode {
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture)
        
        return node
    }
}
