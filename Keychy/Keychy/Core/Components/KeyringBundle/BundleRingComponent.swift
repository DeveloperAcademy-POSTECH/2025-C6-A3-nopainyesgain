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
    static func createHamburgerRingNode(
        image: UIImage,
        ringType: RingType
    ) -> SKSpriteNode {
        let ringSize = ringType.size
        
        // 이미지로 스프라이트 노드 생성
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture)
        
        // 원본 비율 유지하면서 크기 조절
        let originalSize = texture.size()
        let aspectRatio = originalSize.width / originalSize.height
        
        if aspectRatio >= 1.0 {
            // 가로가 더 긴 경우: 가로를 ringSize에 맞춤
            node.size = CGSize(width: ringSize, height: ringSize / aspectRatio)
        } else {
            // 세로가 더 긴 경우: 세로를 ringSize에 맞춤
            node.size = CGSize(width: ringSize * aspectRatio, height: ringSize)
        }

        // 물리 바디 계산을 실제 크기 기준으로
        let actualWidth = node.size.width
        let actualHeight = node.size.height
        let outerRadius = max(actualWidth, actualHeight) / 2
        let innerRadius = outerRadius * 0.84
        let thickness = outerRadius - innerRadius
        
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
    // plain 카라비너의 ring은 고정점 역할 (static physics body)
    static func createPlainRingNode(
        image: UIImage,
        ringType: RingType
    ) -> SKSpriteNode {
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture)
        
        // 원본 비율 유지하면서 크기 조절
        let originalSize = texture.size()
        let aspectRatio = originalSize.width / originalSize.height
        let ringSize = ringType.size
        
        if aspectRatio >= 1.0 {
            // 가로가 더 긴 경우: 가로를 ringSize에 맞춤
            node.size = CGSize(width: ringSize, height: ringSize / aspectRatio)
        } else {
            // 세로가 더 긴 경우: 세로를 ringSize에 맞춤
            node.size = CGSize(width: ringSize * aspectRatio, height: ringSize)
        }
        
        // Plain 타입도 physicsBody 필요 (조인트 연결용, 하지만 static)
        let actualWidth = node.size.width
        let actualHeight = node.size.height
        let physicsRadius = max(actualWidth, actualHeight) / 2
        
        let physicsBody = SKPhysicsBody(circleOfRadius: physicsRadius)
        physicsBody.isDynamic = false  // Static으로 고정 (절대 움직이지 않음)
        physicsBody.mass = 0.1
        physicsBody.friction = 0.4
        physicsBody.restitution = 0.3
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.8
        node.physicsBody = physicsBody
        
        return node
    }
}
