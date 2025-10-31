//
//  KeyringCellScene+Setup.swift
//  KeytschPrototype
//

import SwiftUI
import SpriteKit

// MARK: - Setup & Assembly
extension KeyringCellScene {
    
    // MARK: - 키링 전체 조립
    func setupKeyring() {
        // 모든 이미지를 먼저 다운로드
        downloadAllImages { [weak self] result in
            guard let self = self else {
                print("KeyringCellScene - self가 해제됨")
                return
            }
            
            switch result {
            case .success(let images):
                
                // 다운로드된 이미지로 키링 조립
                self.assembleKeyring(with: images)
                
            case .failure(let error):
                print("이미지 다운로드 실패: \(error)")
                
                // 실패해도 가능한 것만 조립 (fallback)
                // 필요없으면 빼도 됨... 얜 어떻게 처리할지...
                self.assembleFallbackKeyring()
            }
        }
    }
    
    // MARK: - 모든 이미지 다운로드
    private func downloadAllImages(completion: @escaping (Result<KeyringImages, Error>) -> Void) {
        Task {
            do {
                // Ring 이미지 다운로드
                let ringImage = try await StorageManager.shared.getImage(path: currentRingType.imageURL)
                
                // Chain 이미지들 다운로드 (병렬)
                let chainLinks = currentChainType.createChainLinks(length: 7)
                let chainImages = try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
                    var images: [Int: UIImage] = [:]
                    
                    for (index, link) in chainLinks.enumerated() {
                        group.addTask {
                            let image = try await StorageManager.shared.getImage(path: link.imageURL)
                            return (index, image)
                        }
                    }
                    
                    for try await (index, image) in group {
                        images[index] = image
                    }
                    
                    return images
                }
                
                // Body 이미지 다운
                var processedBodyImage: UIImage?
                if let bodyImageURL = self.bodyImage {
                    // 1. 이미지 다운로드
                    let downloadedImage = try await StorageManager.shared.getImage(path: bodyImageURL)
                    
                    // 2. 이미지 처리 (메인 스레드가 아닌 백그라운드에서 실행)
                    processedBodyImage = await Task.detached(priority: .userInitiated) {
                        // orientation 정규화
                        let fixedImage = downloadedImage.fixedOrientation()
                        
                        // 아크릴 테두리만 적용
                        let strokedImage = fixedImage.addAcrylicStroke()
                        
                        return strokedImage ?? fixedImage
                    }.value
                }
                
                await MainActor.run {
                    let images = KeyringImages(
                        ring: ringImage,
                        chains: chainImages,
                        chainLinks: chainLinks,
                        body: processedBodyImage
                    )
                    completion(.success(images))
                }
                
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 키링 조립 (이미지 다운로드 완료 후)
    private func assembleKeyring(with images: KeyringImages) {
        let centerX: CGFloat = 0
        let topY = originalSize.height * 0.67 - (originalSize.height / 2)

        // 1. Ring 생성
        let ring = createRingNode(image: images.ring)
        ring.position = CGPoint(x: centerX, y: topY)
        ring.physicsBody?.isDynamic = false
        containerNode.addChild(ring)
        
        // 2. Chain 생성
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        let chainStartY = ringBottomY
        let chainSpacing: CGFloat = 17
        
        var chains: [SKSpriteNode] = []
        for (index, chainImage) in images.chains.sorted(by: { $0.key < $1.key }) {
            let link = images.chainLinks[index]
            let yPosition = chainStartY - CGFloat(index) * chainSpacing
            
            let chainNode = createChainLinkNode(
                image: chainImage,
                link: link,
                position: CGPoint(x: centerX, y: yPosition),
                index: index
            )
            
            containerNode.addChild(chainNode)
            chains.append(chainNode)
        }
        
        // 3. Body 생성
        var body: SKNode
        if let bodyImage = images.body {
            body = createMiniImageBody(image: bodyImage)
        } else {
            body = createBasicBody()
        }
        
        // Body 위치 계산
        let bodyFrame = body.calculateAccumulatedFrame()
        let bodyHalfHeight = bodyFrame.height / 2
        
        let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
        
        let lastLinkHeight: CGFloat = chains.last.map { $0.calculateAccumulatedFrame().height } ?? chainSpacing
        let lastChainBottomY = lastChainY - lastLinkHeight / 2
        
        // 체인과 바디 사이 여유 간격: 화면 비율 또는 바디 크기 비율(중 하나 선택)
//        let gapByScreen = size.height * 0.01
//        let gapByBody = bodyFrame.height * 0.03
//        let gap = max(gapByScreen, gapByBody)
        let connectGap = 20.0
        //let gap = gapByScreen
        
        let bodyCenterY = lastChainBottomY - bodyHalfHeight + connectGap
        
        body.position = CGPoint(x: centerX, y: bodyCenterY)
        containerNode.addChild(body)
        
        // 4. 조인트 연결
        connectComponents(ring: ring, chains: chains, body: body)
        
        self.onLoadingComplete?()
    }
    
    // MARK: - Fallback 키링 조립 (다운로드 실패 시)
    private func assembleFallbackKeyring() {
        // Fallback시 기본 키링 생성
        
        let centerX: CGFloat = 0
        let topY = originalSize.height * 0.67 - (originalSize.height / 2)
        
        // 기본 Ring (회색 원)
        let ring = SKShapeNode(circleOfRadius: 40)
        ring.fillColor = .clear
        ring.strokeColor = .white
        ring.lineWidth = 8
        ring.position = CGPoint(x: centerX, y: topY)
        
        let ringPhysics = SKPhysicsBody(circleOfRadius: 40)
        ringPhysics.isDynamic = false
        ring.physicsBody = ringPhysics
        containerNode.addChild(ring)
        
        // 기본 Body만 추가
        let body = createBasicBody()
        body.position = CGPoint(x: centerX, y: topY - 200)
        containerNode.addChild(body)
        
        self.onLoadingComplete?()
    }
    
    // MARK: - Ring 노드 생성
    private func createRingNode(image: UIImage) -> SKSpriteNode {
        let ringSize = currentRingType.size
        let outerRadius = ringSize / 2
        let innerRadius = outerRadius * 0.84
        let thickness = outerRadius - innerRadius
        
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture)
        node.size = CGSize(width: ringSize, height: ringSize)
        
        // 물리 바디 (도넛 형태)
        let segments = 32
        var bodies: [SKPhysicsBody] = []
        
        for i in 0..<segments {
            let angle = (CGFloat(i) / CGFloat(segments)) * .pi * 2
            let avgRadius = (outerRadius + innerRadius) / 2
            let x = cos(angle) * avgRadius
            let y = sin(angle) * avgRadius
            
            let segmentBody = SKPhysicsBody(
                circleOfRadius: thickness / 2,
                center: CGPoint(x: x, y: y)
            )
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
    
    // MARK: - Chain 노드 생성
    private func createChainLinkNode(
        image: UIImage,
        link: ChainType.ChainLink,
        position: CGPoint,
        index: Int
    ) -> SKSpriteNode {
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture)
        node.size = link.size
        node.position = position
        node.zPosition = (index % 2 == 0) ? 1 : 0
        
        let physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(width: link.width - 4, height: link.height - 4)
        )
        physicsBody.mass = 2.0
        physicsBody.friction = 0.4
        physicsBody.restitution = 0.3
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.8
        node.physicsBody = physicsBody
        
        return node
    }
    
    // MARK: - Mini Body 생성
    private func createMiniImageBody(image: UIImage) -> SKSpriteNode {
        // 크기 제한 (비율 유지)
        let maxSize: CGFloat = 200
        let originalSize = image.size
        var displaySize = originalSize
        
        let maxDimension = max(originalSize.width, originalSize.height)
        if maxDimension > maxSize {
            let scale = maxSize / maxDimension
            displaySize = CGSize(
                width: originalSize.width * scale,
                height: originalSize.height * scale
            )
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let spriteNode = SKSpriteNode(texture: texture, size: displaySize)
        
        let physicsBody = SKPhysicsBody(rectangleOf: displaySize)
        physicsBody.mass = 3.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        spriteNode.physicsBody = physicsBody
        
        return spriteNode
    }
    
    // MARK: - 기본 Body 생성
    private func createBasicBody() -> SKShapeNode {
        let radius: CGFloat = 40
        let path = CGPath(
            ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
            transform: nil
        )
        
        let node = SKShapeNode(path: path)
        node.fillColor = .white
        node.strokeColor = UIColor(white: 0.8, alpha: 0.4)
        node.lineWidth = 1.0
        
        let physicsBody = SKPhysicsBody(circleOfRadius: radius - 2)
        physicsBody.mass = 2.0
        physicsBody.friction = 0.5
        physicsBody.restitution = 0.2
        physicsBody.linearDamping = 0.8
        physicsBody.angularDamping = 0.95
        node.physicsBody = physicsBody
        
        return node
    }
    
    // MARK: - 조인트 연결
    private func connectComponents(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        
        var previousNode: SKNode = ring
        
        // Ring과 첫 번째 Chain 연결
        if let firstChain = chains.first {
            let ringWorldPos = containerNode.convert(ring.position, to: self)
            let firstChainWorldPos = containerNode.convert(firstChain.position, to: self)
            
            let joint = SKPhysicsJointPin.joint(
                withBodyA: ring.physicsBody!,
                bodyB: firstChain.physicsBody!,
                anchor: CGPoint(
                    x: (ringWorldPos.x + firstChainWorldPos.x) / 2,
                    y: ringWorldPos.y
                )
            )
            joint.shouldEnableLimits = false
            joint.frictionTorque = 0.2
            physicsWorld.add(joint)
            
            let distance = hypot(
                firstChain.position.x - ring.position.x,
                firstChain.position.y - ring.position.y
            ) * scaleFactor
            
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: ring.physicsBody!,
                bodyB: firstChain.physicsBody!,
                anchorA: .zero,
                anchorB: .zero
            )
            limitJoint.maxLength = distance * 1.05
            physicsWorld.add(limitJoint)
            
            firstChain.physicsBody?.linearDamping = 0.7
            firstChain.physicsBody?.angularDamping = 0.7
            previousNode = firstChain
        }
        
        // Chain 링크들 연결
        for i in 1..<chains.count {
            let current = chains[i]
            guard let previous = previousNode.physicsBody else { continue }
            
            let previousWorldPos = containerNode.convert(previousNode.position, to: self)
            let currentWorldPos = containerNode.convert(current.position, to: self)
            
            let joint = SKPhysicsJointPin.joint(
                withBodyA: previous,
                bodyB: current.physicsBody!,
                anchor: CGPoint(
                    x: (previousWorldPos.x + currentWorldPos.x) / 2,
                    y: (previousWorldPos.y + currentWorldPos.y) / 2
                )
            )
            joint.frictionTorque = 0.2
            physicsWorld.add(joint)
            
            let distance = hypot(
                current.position.x - previousNode.position.x,
                current.position.y - previousNode.position.y
            ) * scaleFactor
            
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: previous,
                bodyB: current.physicsBody!,
                anchorA: .zero,
                anchorB: .zero
            )
            limitJoint.maxLength = distance * 1.05
            physicsWorld.add(limitJoint)
            
            current.physicsBody?.linearDamping = 0.7
            current.physicsBody?.angularDamping = 0.7
            previousNode = current
        }
        
        // 마지막 Chain과 Body 연결
        if let lastChain = chains.last, let bodyPhysics = body.physicsBody {
            let lastChainWorldPos = containerNode.convert(lastChain.position, to: self)
            
            let joint = SKPhysicsJointFixed.joint(
                withBodyA: lastChain.physicsBody!,
                bodyB: bodyPhysics,
                anchor: lastChainWorldPos
            )
            physicsWorld.add(joint)
            
            let distance = hypot(
                body.position.x - lastChain.position.x,
                body.position.y - lastChain.position.y
            ) * scaleFactor
            
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: lastChain.physicsBody!,
                bodyB: bodyPhysics,
                anchorA: .zero,
                anchorB: .zero
            )
            limitJoint.maxLength = distance * 1.05
            physicsWorld.add(limitJoint)
            
            bodyPhysics.linearDamping = 0.7
            bodyPhysics.angularDamping = 0.7
        }
    }
}

// MARK: - Keyring 완전체 구조체
struct KeyringImages {
    let ring: UIImage
    let chains: [Int: UIImage]
    let chainLinks: [ChainType.ChainLink]
    let body: UIImage?
}
