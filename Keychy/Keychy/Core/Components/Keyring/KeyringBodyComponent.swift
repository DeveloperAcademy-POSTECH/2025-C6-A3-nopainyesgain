//
//  KeyringBodyComponent.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/18/25.
//

import UIKit
import SpriteKit

// MARK: - Keyring Body Component
struct KeyringBodyComponent {

    static func createNode(
        from bodyImage: UIImage,
        completion: @escaping (SKNode?) -> Void
    ) {
        let node = createImageBody(image: bodyImage)
        completion(node)
    }
    
    // MARK: - String URL로 노드 생성 (비동기)
    static func createNode(
        from bodyImageURL: String,
        completion: @escaping (SKNode?) -> Void
    ) {
        Task {
            do {
                let image = try await StorageManager.shared.getImage(path: bodyImageURL)

                await MainActor.run {
                    let node = createMiniImageBody(image: image)
                    completion(node)
                }
            } catch {
                print("Body 이미지 로드 실패: \(error)")

                await MainActor.run {
                    let node = createBasicBody()
                    completion(node)
                }
            }
        }
    }

    // MARK: - Multi용 String URL로 노드 생성 (비동기, 150x300 aspect fit)
    static func createNodeForMulti(
        from bodyImageURL: String,
        completion: @escaping (SKNode?) -> Void
    ) {
        Task {
            do {
                let image = try await StorageManager.shared.getImage(path: bodyImageURL)

                await MainActor.run {
                    let node = createMultiImageBody(image: image)
                    completion(node)
                }
            } catch {
                print("Body 이미지 로드 실패: \(error)")

                await MainActor.run {
                    let node = createBasicBody()
                    completion(node)
                }
            }
        }
    }
    
    // Body 타입 받아서 SKNode로 생성
    static func createNode(from bodyType: BodyType) -> SKNode {
        switch bodyType {
        case .basic:
            return createBasicBody()
        case .customImage(let image):
            return createImageBody(image: image)
        }
    }

    // MARK: - Basic Body
    private static func createBasicBody() -> SKShapeNode {
        let radius: CGFloat = 80

        // 원형 바디
        let path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)

        let node = SKShapeNode(path: path)
        node.fillColor = .white
        node.strokeColor = UIColor(white: 0.8, alpha: 0.4)
        node.lineWidth = 1.0
        node.zPosition = -1  // Body는 체인 아래

        // 물리 바디 설정 (원형 - 기본값으로 설정, 씬에서 조정됨)
        let physicsBody = SKPhysicsBody(circleOfRadius: radius - 2)
        physicsBody.isDynamic = true  // 기본값은 움직이게 설정, 나중에 씬에서 조정
        physicsBody.affectedByGravity = true  // 기본값은 중력 적용, 나중에 씬에서 조정
        physicsBody.mass = 3.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.6
        physicsBody.angularDamping = 0.9
        node.physicsBody = physicsBody

        return node
    }

    // MARK: - Image Body
    private static func createImageBody(image: UIImage) -> SKNode {
        let displaySize = image.size

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let spriteNode = SKSpriteNode(texture: texture, size: displaySize)
        spriteNode.zPosition = -1  // Body는 체인 아래

        // 물리 바디 설정 (원본 크기에 맞게)
        let physicsBody = SKPhysicsBody(rectangleOf: displaySize)
        // 기본값은 움직이게+중력 적용 설정, 나중에 씬에서 조정 가능.
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = true
        physicsBody.mass = 6.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        spriteNode.physicsBody = physicsBody

        return spriteNode
    }
    
    // 셀용
    private static func createMiniImageBody(image: UIImage) -> SKNode {
        let displaySize = CGSize(width: 150, height: 150)

        // 텍스처 생성
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear   // 부드럽게 렌더링
        let spriteNode = SKSpriteNode(texture: texture, size: displaySize)
        spriteNode.zPosition = -1  // Body는 체인 아래

        // 물리 바디 설정 (원본 크기에 맞게)
        let physicsBody = SKPhysicsBody(rectangleOf: displaySize)
        physicsBody.isDynamic = true  // 기본값은 움직이게 설정, 나중에 씬에서 조정
        physicsBody.affectedByGravity = true  // 기본값은 중력 적용, 나중에 씬에서 조정
        physicsBody.mass = 6.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        spriteNode.physicsBody = physicsBody

        return spriteNode
    }

    // MARK: - Multi용 (150x300 aspect fit)
    private static func createMultiImageBody(image: UIImage) -> SKNode {
        let maxSize = CGSize(width: 150, height: 300)
        let originalSize = image.size

        // Aspect fit 계산: 원본 비율 유지하며 150x300 안에 들어가도록
        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let scale = min(widthRatio, heightRatio)

        let displaySize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        // 텍스처 생성
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let spriteNode = SKSpriteNode(texture: texture, size: displaySize) // displaySize -> originalSize로 사용
        spriteNode.zPosition = -1  // Body는 체인 아래

        // 물리 바디 설정
        let physicsBody = SKPhysicsBody(rectangleOf: displaySize)
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = true
        physicsBody.mass = 6.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        spriteNode.physicsBody = physicsBody

        return spriteNode
    }
}
