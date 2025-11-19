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
            
            // containerNode가 nil이면 재시도
            guard self.containerNode != nil else {
                print("이미지 다운로드 완료 후에도 containerNode가 nil입니다. 0.1초 후 재시도합니다.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    // 이미지는 이미 다운로드되었으므로 조립만 재시도
                    switch result {
                    case .success(let images):
                        self?.assembleKeyring(with: images)
                    case .failure:
                        self?.assembleFallbackKeyring()
                    }
                }
                return
            }
            
            switch result {
            case .success(let images):
                self.assembleKeyring(with: images)
            case .failure(let error):
                print("이미지 다운로드 실패: \(error)")
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
                let chainLinks = currentChainType.createChainLinks(length: 5) // 이후 수정 필요
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
                        let fixedImage = await downloadedImage.fixedOrientation()
                        
                        return fixedImage
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
        guard let containerNode = containerNode else {
            print("containerNode가 nil입니다. Scene이 아직 준비되지 않았습니다.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.assembleKeyring(with: images)
            }
            return
        }
        
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
        let chainStartY = ringBottomY - 2
        let chainSpacing: CGFloat = 20
        
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

        // hookOffsetY를 사용한 정확한 연결 지점 계산
        // hookOffsetYRatio: 원본 이미지(아크릴 효과 전) 높이 대비 구멍 위치 비율 (0.0 ~ 1.0)
        //                   0.0 = 이미지 상단, 1.0 = 이미지 하단
        // actualHookOffsetY: Scene의 실제 body 크기에 맞게 변환된 픽셀 값
        let hookOffsetYRatio = hookOffsetY ?? 0.0
        let actualHookOffsetY = hookOffsetYRatio * bodyFrame.height

        // Body 중심 Y 계산: 체인 끝에서 body 절반만큼 내리고, 구멍 위치만큼 올림
        let bodyCenterY = lastChainBottomY - bodyHalfHeight + actualHookOffsetY + 4 // 4는 조절값

        body.position = CGPoint(x: centerX, y: bodyCenterY)
        body.zPosition = -1  // Body는 체인 아래
        containerNode.addChild(body)

        // 4. 조인트 연결
        connectComponents(ring: ring, chains: chains, body: body)
        
        self.onLoadingComplete?()
    }
    
    // MARK: - Fallback 키링 조립 (다운로드 실패 시)
    private func assembleFallbackKeyring() {
        guard let containerNode = containerNode else {
            print("containerNode가 nil입니다. Scene이 아직 준비되지 않았습니다.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.assembleFallbackKeyring()
            }
            return
        }
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
        // Physics 카테고리 정의
        let chainCategory: UInt32 = 0x1 << 0  // 1
        let bodyCategory: UInt32 = 0x1 << 1   // 2

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

            // Physics 카테고리 설정 (체인끼리만 충돌)
            firstChain.physicsBody?.categoryBitMask = chainCategory
            firstChain.physicsBody?.collisionBitMask = chainCategory

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

            // Physics 카테고리 설정 (체인끼리만 충돌)
            current.physicsBody?.categoryBitMask = chainCategory
            current.physicsBody?.collisionBitMask = chainCategory

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

            // Physics 카테고리 설정 (Body는 아무것과도 충돌하지 않음, Joint로만 연결)
            bodyPhysics.categoryBitMask = bodyCategory
            bodyPhysics.collisionBitMask = 0  // 아무것과도 충돌하지 않음
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
