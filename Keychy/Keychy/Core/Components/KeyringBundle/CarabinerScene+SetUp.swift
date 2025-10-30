//
//  CarabinerScene+SetUp.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SpriteKit

// MARK: - Setup & Assembly
extension CarabinerScene {
    
    // 카라비너 + 여러 키링 전체 조립
    func setupCarabinerWithKeyrings() {
        let centerX: CGFloat = 0
        // 곱하는 숫자가 높아질 수록 화면 위로 올라가는데, 너무 많이 올리면 화면 밖으로 나가서 아예 안 보이니 주의할 것.
        // 0.3 정도가 적당함
        let topY = originalSize.height * 0.3
        
        // 1. 카라비너 생성 (루트 노드)
        let madeCarabiner = createCarabiner()
        madeCarabiner.position = CGPoint(x: centerX, y: topY)
        madeCarabiner.physicsBody?.isDynamic = false
        containerNode.addChild(madeCarabiner)
        carabinerNode = madeCarabiner
        
        // 2. 키링들 비동기 생성
        createKeyringsAsync(for: madeCarabiner)
    }
    
    // 키링들을 비동기로 생성 (외부에서도 호출 가능하도록 public으로 변경)
    func createKeyringsAsync(for carabiner: SKSpriteNode) {
        let carabinerSize = carabiner.size
        var completedKeyrings = 0
        let totalKeyrings = bodyImages.count
        
        guard totalKeyrings > 0 else {
            onSceneReady?()
            return
        }
        
        for (index, bodyImage) in bodyImages.enumerated() {
            // Carabiner 모델에서 가져온 비율 (0.0 ~ 1.0 범위)
            let nx = getKeyringXPosition(for: index)  // 비율
            let ny = getKeyringYPosition(for: index)  // 비율
            
            // 실제 좌표 = 카라비너 크기 * 비율
            let xOffset = (nx - 0.5) * carabinerSize.width   // 중심 기준
            let yOffset = (ny - 0.5) * carabinerSize.height  // 중심 기준
            
            // 키링 생성
            setupKeyringNode(
                bodyImage: bodyImage,
                position: CGPoint(x: xOffset, y: yOffset),
                parent: carabiner,
                index: index
            ) { [weak self] keyring in
                guard let self = self else { return }
                
                self.keyrings.append(keyring)
                completedKeyrings += 1
                
                // 모든 키링이 완성되면 콜백 호출
                if completedKeyrings == totalKeyrings {
                    DispatchQueue.main.async {
                        self.onSceneReady?()
                    }
                }
            }
        }
    }
    
    // 개별 키링 조립 (비동기 처리)
    func setupKeyringNode(
        bodyImage: UIImage,
        position: CGPoint,
        parent: SKNode,
        index: Int,
        completion: @escaping (SKNode) -> Void
    ) {
        let keyringContainer = SKNode()
        keyringContainer.position = position
        keyringContainer.name = "keyring_\(index)"
        parent.addChild(keyringContainer)
        
        let centerX: CGFloat = 0
        
        // 1. Ring 생성
        KeyringRingComponent.createNode(from: currentRingType) { [weak self] ring in
            guard let self = self, let ring = ring else {
                completion(keyringContainer)
                return
            }
            // 뭉치함에선 키링의 링 사이즈를 작게 조절함
            //⭐️ TODO: 사이즈 얼마정도가 괜찮을지 싱싱이랑 이야기 해보기
            ring.setScale(0.4)
            
            // Ring의 상단이 버튼 위치에 오도록 조정
            let ringFrame = ring.calculateAccumulatedFrame()
            let ringRadius = ringFrame.height / 2
            
            // Ring을 아래로 이동
            ring.position = CGPoint(x: centerX, y: -ringRadius)
            ring.physicsBody?.isDynamic = false
            keyringContainer.addChild(ring)
            
            // 2. Chain 생성 (Ring 생성 후)
            self.setupChain(ring: ring, centerX: centerX, container: keyringContainer, bodyImage: bodyImage, index: index, completion: completion)
        }
    }
    
    // Chain 생성 (Ring 생성 후 호출)
    private func setupChain(
        ring: SKSpriteNode,
        centerX: CGFloat,
        container: SKNode,
        bodyImage: UIImage,
        index: Int,
        completion: @escaping (SKNode) -> Void
    ) {
        
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        let chainStartY = ringBottomY + 0.5
        let chainSpacing: CGFloat = 16
        
        KeyringChainComponent.createLinks(
            from: currentChainType,
            count: 6,
            startPosition: CGPoint(x: centerX, y: chainStartY),
            spacing: chainSpacing
        ) { [weak self] chains in
            guard let self = self else {
                completion(container)
                return
            }
            
            // 체인 노드를 컨테이너에 추가
            for chain in chains {
                container.addChild(chain)
            }
            
            // 3. Body 생성 (체인 생성 후)
            self.setupBody(
                ring: ring,
                chains: chains,
                centerX: centerX,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing,
                container: container,
                bodyImage: bodyImage,
                index: index,
                completion: completion
            )
        }
    }
    
    // Body 생성 및 연결 (Chain 생성 후 호출)
    private func setupBody(
        ring: SKSpriteNode,
        chains: [SKSpriteNode],
        centerX: CGFloat,
        chainStartY: CGFloat,
        chainSpacing: CGFloat,
        container: SKNode,
        bodyImage: UIImage,
        index: Int,
        completion: @escaping (SKNode) -> Void
    ) {
        // UIImage로 Body 생성
        KeyringBodyComponent.createNode(from: bodyImage) { [weak self] body in
            guard let self = self, let body = body else {
                completion(container)
                return
            }
            body.setScale(0.6)
            self.positionAndConnectBody(
                body: body,
                ring: ring,
                chains: chains,
                centerX: centerX,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing,
                container: container,
                index: index
            )
            
            completion(container)
        }
    }
    
    // Body 위치 설정 및 연결
    private func positionAndConnectBody(
        body: SKNode,
        ring: SKSpriteNode,
        chains: [SKSpriteNode],
        centerX: CGFloat,
        chainStartY: CGFloat,
        chainSpacing: CGFloat,
        container: SKNode,
        index: Int
    ) {
        
        // Body의 실제 누적 프레임
        let bodyFrame = body.calculateAccumulatedFrame()
        let bodyHalfHeight = bodyFrame.height / 2
        
        // Body 위치 설정
        let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
        let lastLinkHeight: CGFloat = chains.last?.calculateAccumulatedFrame().height ?? chainSpacing
        let lastChainBottomY = lastChainY - lastLinkHeight / 2
        
        let gapByScreen = originalSize.height * 0.01
        let gapByBody = bodyFrame.height * 0.03
        let gap = max(gapByScreen, gapByBody)
        
        let bodyCenterY = lastChainBottomY - gap - bodyHalfHeight
        
        body.position = CGPoint(x: centerX, y: bodyCenterY)
        body.setScale(0.5)
        container.addChild(body)
        
        // 조인트 연결
        connectComponents(ring: ring, chains: chains, body: body)
    }

    func connectComponents(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        if isPhysicsEnabled {
            // 물리 시뮬레이션 활성화된 경우: 조인트로 연결하여 움직이게 함 -> 홈화면, 뭉치 디테일뷰 등에서 사용
            connectComponentsWithPhysics(ring: ring, chains: chains, body: body)
        } else {
            // 물리 시뮬레이션 비활성화된 경우: 모든 구성 요소를 완전히 고정 -> 뭉치 만들기 뷰에서 사용
            fixAllComponents(ring: ring, chains: chains, body: body)
        }
    }
    
    // 물리 시뮬레이션 활성화 시: 조인트로 연결
    private func connectComponentsWithPhysics(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
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
            
            // 물리 속성 설정 (움직이게 함)
            firstChain.physicsBody?.isDynamic = true
            firstChain.physicsBody?.affectedByGravity = true
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
            
            // 물리 속성 설정 (움직이게 함)
            current.physicsBody?.isDynamic = true
            current.physicsBody?.affectedByGravity = true
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
            
            // Body 물리 속성 설정 (움직이게 함)
            bodyPhysics.isDynamic = true
            bodyPhysics.affectedByGravity = true
            bodyPhysics.linearDamping = 0.7
            bodyPhysics.angularDamping = 0.7
        }
    }
    
    // 물리 시뮬레이션 비활성화 시: 모든 구성 요소 고정
    private func fixAllComponents(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        // Ring을 완전히 고정
        ring.physicsBody?.isDynamic = false
        ring.physicsBody?.affectedByGravity = false
        
        // 모든 Chain 링크들을 완전히 고정
        for chain in chains {
            chain.physicsBody?.isDynamic = false
            chain.physicsBody?.affectedByGravity = false
        }
        
        // Body를 완전히 고정
        body.physicsBody?.isDynamic = false
        body.physicsBody?.affectedByGravity = false
    }
}

// MARK: - Carabiner Creation
extension CarabinerScene {
    
    func createCarabiner() -> SKSpriteNode {
        let carabiner = SKSpriteNode()
        
        if let image = carabinerImage {
            carabiner.texture = SKTexture(image: image)
            
            // 기기 화면 가로 크기의 0.5배로 카라비너 크기 설정
            let carabinerWidth = screenWidth * 0.5
            // 원본 이미지의 비율 유지
            let aspectRatio = image.size.height / image.size.width
            let carabinerHeight = carabinerWidth * aspectRatio
            
            carabiner.size = CGSize(width: carabinerWidth, height: carabinerHeight)
        }
        
        carabiner.physicsBody = SKPhysicsBody(rectangleOf: carabiner.size)
        // 물리 설정, 중력 설정 끔
        carabiner.physicsBody?.isDynamic = false
        carabiner.physicsBody?.affectedByGravity = false
        
        return carabiner
    }
}

// MARK: - 비율 기반 위치 계산
extension CarabinerScene {
    
    /// 각 키링의 X 위치 비율 (0.0 ~ 1.0)
    func getKeyringXPosition(for index: Int) -> CGFloat {
        // Carabiner 모델과 연동
        if let carabiner = carabiner,
           index < carabiner.keyringXPosition.count {
            return CGFloat(carabiner.keyringXPosition[index])
        }
        // 임의로 설정한 기본값
        return 0.5
    }
    
    /// 각 키링의 Y 위치 비율 (0.0 ~ 1.0)
    func getKeyringYPosition(for index: Int) -> CGFloat {
        // Carabiner 모델과 연동
        if let carabiner = carabiner,
           index < carabiner.keyringYPosition.count {
            return CGFloat(carabiner.keyringYPosition[index])
        }
        // 임의로 설정한 기본값
        return 0.5
    }
}

// MARK: - Array Extension (안전한 접근)
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
