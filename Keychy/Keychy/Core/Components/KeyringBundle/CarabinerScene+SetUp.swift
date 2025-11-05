//
//  CarabinerScene+SetUp.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SpriteKit

// MARK: - Setup & Assembly
extension CarabinerScene {
    
    // 카라비너 + 여러 키링 전체 조립 (컨테이너 없이 직접 연결)
    func setupCarabinerWithKeyrings() {
        let centerX: CGFloat = size.width / 2
        let topY = (size.height / 2) + (originalSize.height * scaleFactor * 0.3 / 2)
        
        // 1. 뒷면 카라비너 생성 (씬에 직접 추가)
        let backCarabiner = createCarabiner()
        backCarabiner.position = CGPoint(x: centerX, y: topY)
        backCarabiner.setScale(scaleFactor)
        backCarabiner.physicsBody?.isDynamic = false
        addChild(backCarabiner)
        carabinerNode = backCarabiner
        
        // 2. 앞면 카라비너 생성 (오버레이용)
        if let frontImage = carabinerFrontImage {
            let frontCarabiner = createCarabinerFront(with: frontImage)
            frontCarabiner.position = CGPoint(x: centerX, y: topY)
            frontCarabiner.setScale(scaleFactor)
            frontCarabiner.physicsBody?.isDynamic = false
            // 앞면은 씬에 직접 추가 (키링들 위에 오버레이)
            addChild(frontCarabiner)
            carabinerFrontNode = frontCarabiner
            
            // zPosition 설정으로 레이어 순서 보장
            backCarabiner.zPosition = 0  // 맨 뒤
            // 키링들은 setupKeyringNode에서 zPosition = 1로 설정될 예정
            frontCarabiner.zPosition = 2  // 맨 앞
        }
        
        // 3. 키링들 비동기 생성 (씬에 직접 추가)
        createKeyringsAsync(for: backCarabiner)
    }
    
    // 키링들을 비동기로 생성 (컨테이너 없이 직접 씬에 추가)
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
            
            // 카라비너의 실제 위치와 크기를 기준으로 키링 위치 계산
            let xOffset = (nx - 0.5) * carabinerSize.width * scaleFactor
            let yOffset = (ny - 0.5) * carabinerSize.height * scaleFactor
            
            // 절대 좌표 계산
            let absolutePosition = CGPoint(
                x: carabiner.position.x + xOffset,
                y: carabiner.position.y + yOffset
            )
            
            // 키링 생성: 씬에 직접 추가
            setupKeyringNode(
                bodyImage: bodyImage,
                position: absolutePosition,
                parent: self,
                index: index
            ) { [weak self] keyring in
                guard let self else { return }
                
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
    
    // 개별 키링 조립 (물리 시뮬레이션 활성화)
    func setupKeyringNode(
        bodyImage: UIImage,
        position: CGPoint,
        parent: SKNode,
        index: Int,
        completion: @escaping (SKNode) -> Void
    ) {
        // 컨테이너 없이 직접 Ring부터 생성
        // 1. Ring 생성
        KeyringRingComponent.createNode(from: currentRingType) { [weak self] ring in
            guard let self, let ring = ring else {
                // 빈 노드라도 반환해서 카운팅이 맞도록 함
                let emptyNode = SKNode()
                emptyNode.name = "keyring_\(index)"
                parent.addChild(emptyNode)
                completion(emptyNode)
                return
            }
            
            // 링 크기와 위치 설정
            ring.setScale(0.6 * self.scaleFactor)  // scaleFactor 적용
            ring.name = "keyring_\(index)_ring"
            ring.zPosition = 1
            
            // Ring의 상단이 지정된 위치에 오도록 조정
            let ringFrame = ring.calculateAccumulatedFrame()
            let ringRadius = ringFrame.height / 2
            
            // Ring 중심 위치: 지정된 위치에서 반지름만큼 아래로
            let ringCenterX = position.x
            let ringCenterY = position.y - ringRadius
            
            ring.position = CGPoint(x: ringCenterX, y: ringCenterY)
            
            // Ring은 고정 (카라비너에 매달려 있음)
            ring.physicsBody?.isDynamic = false
            ring.physicsBody?.affectedByGravity = false
            
            // 씬에 직접 추가
            parent.addChild(ring)
            
            // 2. Chain 생성 (Ring 생성 후)
            self.setupChain(ring: ring, bodyImage: bodyImage, index: index, parent: parent, completion: completion)
        }
    }
    
    // Chain 생성 (KeyringScene과 동일한 물리 설정)
    private func setupChain(
        ring: SKSpriteNode,
        bodyImage: UIImage,
        index: Int,
        parent: SKNode,
        completion: @escaping (SKNode) -> Void
    ) {
        // Ring의 하단에서 체인 시작
        let ringBottomY = ring.position.y - (ring.calculateAccumulatedFrame().height / 2)
        let chainStartY = ringBottomY + 0.5
        let chainSpacing: CGFloat = 16 * scaleFactor  // scaleFactor 적용
        
        // 체인을 Ring의 위치 기준으로 생성
        KeyringChainComponent.createLinks(
            from: currentChainType,
            count: 5,
            startPosition: CGPoint(x: ring.position.x, y: chainStartY),
            spacing: chainSpacing
        ) { [weak self] chains in
            guard let self else {
                completion(ring) // ring을 반환
                return
            }
            
            // 체인들을 씬에 직접 추가 (KeyringScene과 동일한 기본 물리 설정)
            for (i, chain) in chains.enumerated() {
                chain.setScale(self.scaleFactor) // scaleFactor 적용
                chain.name = "keyring_\(index)_chain_\(i)"
                chain.zPosition = 1
                
                // KeyringScene과 동일: Component에서 설정된 기본 물리 속성 유지
                // isDynamic, affectedByGravity 등을 따로 설정하지 않음
                
                parent.addChild(chain)
            }
            
            // 3. Body 생성 (체인 생성 후)
            self.setupBody(
                ring: ring,
                chains: chains,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing,
                bodyImage: bodyImage,
                index: index,
                parent: parent,
                completion: completion
            )
        }
    }
    
    // Body 생성 및 연결 (KeyringScene과 동일한 물리 설정)
    private func setupBody(
        ring: SKSpriteNode,
        chains: [SKSpriteNode],
        chainStartY: CGFloat,
        chainSpacing: CGFloat,
        bodyImage: UIImage,
        index: Int,
        parent: SKNode,
        completion: @escaping (SKNode) -> Void
    ) {
        // UIImage로 Body 생성
        KeyringBodyComponent.createNode(from: bodyImage) { [weak self] body in
            guard let self, let body = body else {
                completion(ring) // ring을 반환
                return
            }
            
            body.setScale(0.3 * self.scaleFactor)
            body.name = "keyring_\(index)_body"
            body.zPosition = 1
            
            // Body 위치 계산 (KeyringScene과 동일한 방식)
            let bodyFrame = body.calculateAccumulatedFrame()
            let bodyHalfHeight = bodyFrame.height / 2
            
            let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
            let lastLinkHeight: CGFloat = chains.last?.calculateAccumulatedFrame().height ?? chainSpacing
            let lastChainBottomY = lastChainY - lastLinkHeight / 2
            
            let connectGap = 30.0 * self.scaleFactor // scaleFactor 적용
            let bodyCenterY = lastChainBottomY - bodyHalfHeight + connectGap
            
            body.position = CGPoint(x: ring.position.x, y: bodyCenterY)
            
            // KeyringScene과 동일: Component에서 설정된 기본 물리 속성 유지
            // isDynamic, affectedByGravity 등을 따로 설정하지 않음
            
            parent.addChild(body)
            
            // 물리 조인트 연결 (KeyringScene과 동일하게 항상 연결)
            self.connectComponents(ring: ring, chains: chains, body: body)
            
            completion(body)
        }
    }
    
    func connectComponents(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        // KeyringScene과 동일하게 항상 물리 조인트 연결
        connectComponentsWithKeyringSceneStyle(ring: ring, chains: chains, body: body)
    }
    
    // KeyringScene과 완전히 동일한 물리 연결
    private func connectComponentsWithKeyringSceneStyle(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        // Ring은 완전히 고정 (KeyringScene과 완전히 동일)
        ring.physicsBody?.isDynamic = false
        ring.physicsBody?.affectedByGravity = false
        
        print("🔗 KeyringScene 방식 조인트 연결 시작")
        
        var previousNode: SKNode = ring

        // Ring과 첫 번째 Chain 연결 (KeyringScene과 완전히 동일)
        if let firstChain = chains.first {
            // KeyringScene과 동일한 anchor 계산 (씬 기준)
            let anchorY = ring.position.y
            
            let joint = SKPhysicsJointPin.joint(
                withBodyA: ring.physicsBody!,
                bodyB: firstChain.physicsBody!,
                anchor: CGPoint(
                    x: (ring.position.x + firstChain.position.x) / 2,
                    y: anchorY
                )
            )
            joint.shouldEnableLimits = false
            joint.frictionTorque = 0.1  // KeyringScene과 동일한 마찰값
            physicsWorld.add(joint)
            
            // 거리 제한 추가 (KeyringScene과 완전히 동일)
            let distance = hypot(
                firstChain.position.x - ring.position.x,
                firstChain.position.y - ring.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: ring.physicsBody!,
                bodyB: firstChain.physicsBody!,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = distance * 1.05 // KeyringScene과 동일한 5% 여유
            physicsWorld.add(limitJoint)
            
            // 체인의 물리 속성 조정 (KeyringScene과 동일)
            firstChain.physicsBody?.linearDamping = 0.5
            firstChain.physicsBody?.angularDamping = 0.5
            
            previousNode = firstChain
        }

        // Chain 링크들 연결 (KeyringScene과 완전히 동일)
        for i in 1..<chains.count {
            let current = chains[i]
            if let previous = previousNode.physicsBody {
                let joint = SKPhysicsJointPin.joint(
                    withBodyA: previous,
                    bodyB: current.physicsBody!,
                    anchor: CGPoint(
                        x: (previousNode.position.x + current.position.x) / 2,
                        y: (previousNode.position.y + current.position.y) / 2
                    )
                )
                joint.shouldEnableLimits = false
                joint.frictionTorque = 0.1  // KeyringScene과 동일
                physicsWorld.add(joint)
                
                // 거리 제한 추가 (KeyringScene과 완전히 동일)
                let distance = hypot(
                    current.position.x - previousNode.position.x,
                    current.position.y - previousNode.position.y
                )
                let limitJoint = SKPhysicsJointLimit.joint(
                    withBodyA: previous,
                    bodyB: current.physicsBody!,
                    anchorA: CGPoint.zero,
                    anchorB: CGPoint.zero
                )
                limitJoint.maxLength = distance * 1.05  // KeyringScene과 동일한 5% 여유
                physicsWorld.add(limitJoint)
                
                // 체인의 물리 속성 조정 (KeyringScene과 동일)
                current.physicsBody?.linearDamping = 0.05
                current.physicsBody?.angularDamping = 0.05
            }
            previousNode = current
        }

        // 마지막 Chain과 Body 연결 (KeyringScene과 완전히 동일)
        if let lastChain = chains.last, let bodyPhysics = body.physicsBody {
            let joint = SKPhysicsJointFixed.joint(
                withBodyA: lastChain.physicsBody!,
                bodyB: bodyPhysics,
                anchor: CGPoint(
                    x: lastChain.position.x,
                    y: lastChain.position.y
                )
            )
            physicsWorld.add(joint)
            
            // Body와 Chain 사이 거리 제한 (KeyringScene과 동일)
            let distance = hypot(
                body.position.x - lastChain.position.x,
                body.position.y - lastChain.position.y
            )
            let limitJoint = SKPhysicsJointLimit.joint(
                withBodyA: lastChain.physicsBody!,
                bodyB: bodyPhysics,
                anchorA: CGPoint.zero,
                anchorB: CGPoint.zero
            )
            limitJoint.maxLength = distance * 1.05  // KeyringScene과 동일한 5% 여유
            physicsWorld.add(limitJoint)
            
            // Body의 물리 속성 조정 (KeyringScene과 동일)
            bodyPhysics.linearDamping = 0.5
            bodyPhysics.angularDamping = 0.5
        }
        
        print("🔗 KeyringScene 방식 조인트 연결 완료")
        print("🔗 연결된 요소들: Ring(\(ring.position)), Chains(\(chains.count)개), Body(\(body.position))")
    }
    
    // 기존 복잡한 물리 연결 방식 (참고용)
    private func connectComponentsWithComplexPhysics(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        var previousNode: SKNode = ring
        
        // Ring과 첫 번째 Chain 연결
        if let firstChain = chains.first {
            // 컨테이너 제거: 월드 좌표 변환 없이 씬 좌표 사용
            let joint = SKPhysicsJointPin.joint(
                withBodyA: ring.physicsBody!,
                bodyB: firstChain.physicsBody!,
                anchor: CGPoint(
                    x: (ring.position.x + firstChain.position.x) / 2,
                    y: ring.position.y
                )
            )
            joint.shouldEnableLimits = false
            joint.frictionTorque = 0.2
            physicsWorld.add(joint)
            
            let distance = hypot(
                firstChain.position.x - ring.position.x,
                firstChain.position.y - ring.position.y
            )
            
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
            
            let joint = SKPhysicsJointPin.joint(
                withBodyA: previous,
                bodyB: current.physicsBody!,
                anchor: CGPoint(
                    x: (previousNode.position.x + current.position.x) / 2,
                    y: (previousNode.position.y + current.position.y) / 2
                )
            )
            joint.frictionTorque = 0.2
            physicsWorld.add(joint)
            
            let distance = hypot(
                current.position.x - previousNode.position.x,
                current.position.y - previousNode.position.y
            )
            
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
            let joint = SKPhysicsJointFixed.joint(
                withBodyA: lastChain.physicsBody!,
                bodyB: bodyPhysics,
                anchor: lastChain.position
            )
            physicsWorld.add(joint)
            
            let distance = hypot(
                body.position.x - lastChain.position.x,
                body.position.y - lastChain.position.y
            )
            
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
            
            // 기기 화면 가로 크기의 0.7배로 카라비너 크기 설정 (더 크게)
            let carabinerWidth = screenWidth * 0.9
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
    
    // 앞면 카라비너 생성 (햄버거 구조용)
    func createCarabinerFront(with frontImage: UIImage) -> SKSpriteNode {
        let frontCarabiner = SKSpriteNode()
        
        frontCarabiner.texture = SKTexture(image: frontImage)
        
        // 기기 화면 가로 크기의 0.7배로 카라비너 크기 설정 (뒷면과 동일)
        let carabinerWidth = screenWidth * 0.9
        // 원본 이미지의 비율 유지
        let aspectRatio = frontImage.size.height / frontImage.size.width
        let carabinerHeight = carabinerWidth * aspectRatio
        
        frontCarabiner.size = CGSize(width: carabinerWidth, height: carabinerHeight)
        
        // 앞면은 물리 효과 없음 (순수 시각적 오버레이)
        frontCarabiner.physicsBody = nil
        
        return frontCarabiner
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
