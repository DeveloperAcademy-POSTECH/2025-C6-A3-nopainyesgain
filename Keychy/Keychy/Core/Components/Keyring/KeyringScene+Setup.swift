//
//  KeyringScene+Setup.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/18/25.
//

import SpriteKit

// MARK: - Setup & Assembly
extension KeyringScene {

    // 키링 전체 조립
    func setupKeyring() {
        let centerX = size.width / 2
        let topY = size.height * 0.75
        
        // 1. Ring 생성
        KeyringRingComponent.createNode(from: currentRingType) { [weak self] ring in
            guard let self = self, let ring = ring else {
                print("Ring 생성 실패")
                return
            }
            
            ring.position = CGPoint(x: centerX, y: topY)
            ring.physicsBody?.isDynamic = false
            self.addChild(ring)
            self.ringNode = ring
            
            // 2. Chain 생성 (Ring 생성 후)
            self.setupChain(ring: ring, centerX: centerX)
        }
    }
    // Chain 생성 (Ring 생성 후 호출)
    private func setupChain(ring: SKSpriteNode, centerX: CGFloat) {
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        // ringBottomY 그대로가 아니라 -2로 아주 얇은 간격을 줌으로써 보기에 자연스럽게 만드려고 함
        let chainStartY = ringBottomY - 2
        let chainSpacing: CGFloat = 20
        
        
        KeyringChainComponent.createLinks(
            from: currentChainType,
            count: 5,
            startPosition: CGPoint(x: centerX, y: chainStartY),
            spacing: chainSpacing
        ) { [weak self] chains in
            guard let self = self else { return }
            
            // 체인 노드를 씬에 추가
            for chain in chains {
                self.addChild(chain)
                self.chainNodes.append(chain)
            }
            
            // 3. Body 생성 (체인 생성 후)
            self.setupBody(ring: ring, chains: chains, centerX: centerX, chainStartY: chainStartY, chainSpacing: chainSpacing)
        }

    }
    
    // Body 생성 및 연결 (Chain 생성 후 호출)
    private func setupBody(ring: SKSpriteNode, chains: [SKSpriteNode], centerX: CGFloat, chainStartY: CGFloat, chainSpacing: CGFloat) {
        
        if let bodyImage = bodyImage {
            // UIImage인 경우
            KeyringBodyComponent.createNode(
                from: bodyImage
            ) { [weak self] body in
                guard let self = self, let body = body else {
                    print("Body 생성 실패")
                    return
                }
                
                self.positionAndConnectBody(
                    body: body,
                    ring: ring,
                    chains: chains,
                    centerX: centerX,
                    chainStartY: chainStartY,
                    chainSpacing: chainSpacing
                )
            }
        } else if let bodyImageURL = bodyImageURL {
            // URL만 있는 경우
            KeyringBodyComponent.createNode(from: bodyImageURL) { [weak self] body in
                guard let self = self, let body = body else {
                    print("Body 생성 실패")
                    return
                }
                
                self.positionAndConnectBody(
                    body: body,
                    ring: ring,
                    chains: chains,
                    centerX: centerX,
                    chainStartY: chainStartY,
                    chainSpacing: chainSpacing
                )
            }
        } else {
            let body = KeyringBodyComponent.createNode(from: .basic)
            positionAndConnectBody(
                body: body,
                ring: ring,
                chains: chains,
                centerX: centerX,
                chainStartY: chainStartY,
                chainSpacing: chainSpacing
            )
        }
    }
    
    // Body 위치 설정 및 연결
    private func positionAndConnectBody(body: SKNode, ring: SKSpriteNode, chains: [SKSpriteNode], centerX: CGFloat, chainStartY: CGFloat, chainSpacing: CGFloat) {

        // Body의 실제 누적 프레임
        let bodyFrame = body.calculateAccumulatedFrame()
        let bodyHalfHeight = bodyFrame.height / 2

        // Body 위치 설정 (마지막 체인 아래끝과의 간격을 "바디 중앙선의 top" 기준으로)
        // 마지막 체인의 "중심 Y": 첫 링크 시작점에서 (링크 수 - 1) * spacing 만큼 아래
        let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing

        // 마지막 체인의 실제 높이를 기반으로 "아래 끝 Y" 계산 - 15: 체인길이의 절반
        let lastChainBottomY = lastChainY - 15

        // hookOffsetY를 사용한 정확한 연결 지점 계산
        // hookOffsetY가 nil이면 0.0을 사용 (바디 중앙 상단에 연결)
        // hookOffsetY가 양수면 바디 중심에서 위로 이동 (구멍이 더 위에 있음)
        // hookOffsetY가 음수면 바디 중심에서 아래로 이동 (구멍이 더 아래에 있음)
        let bodyCenterY = lastChainBottomY - bodyHalfHeight - (hookOffsetY ?? 0.0)

        body.position = CGPoint(x: centerX, y: bodyCenterY)
        
        body.zPosition = -1  // Body는 체인 아래
        addChild(body)
        bodyNode = body

        // 조인트 연결
        connectComponents(ring: ring, chains: chains, body: body)

        // Setup 완료 알림 (Body까지 완전히 생성됨)
        onSetupComplete?()
    }

    // 키링 구성 요소들을 Joint로 연결
    private func connectComponents(ring: SKSpriteNode, chains: [SKSpriteNode], body: SKNode) {
        var previousNode: SKNode = ring

        // Ring과 첫 번째 Chain 연결
        if let firstChain = chains.first {
            let anchorY = previousNode.position.y
            
            let joint = SKPhysicsJointPin.joint(
                withBodyA: ring.physicsBody!,
                bodyB: firstChain.physicsBody!,
                anchor: CGPoint(
                    x: (ring.position.x + firstChain.position.x) / 2,
                    y: anchorY
                )
            )
            joint.shouldEnableLimits = false
            joint.frictionTorque = 0.1 // 약간의 마찰로 자연스러운 움직임
            physicsWorld.add(joint)
            
            // 거리 제한 - 실제 체인처럼 늘어나지 않도록
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
            limitJoint.maxLength = distance * 1.05 // 약간의 여유 (5%)
            physicsWorld.add(limitJoint)
            
            // 체인의 물리 속성 조정 (더 유연하게)
            firstChain.physicsBody?.linearDamping = 0.5
            firstChain.physicsBody?.angularDamping = 0.5
            
            previousNode = firstChain
        }

        // Chain 링크들 연결
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
                joint.frictionTorque = 0.1
                physicsWorld.add(joint)
                
                // 거리 제한 - 실제 체인처럼 늘어나지 않도록
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
                limitJoint.maxLength = distance * 1.05 // 약간의 여유 (5%)
                physicsWorld.add(limitJoint)
                
                // 체인의 물리 속성 조정
                current.physicsBody?.linearDamping = 0.05
                current.physicsBody?.angularDamping = 0.05
            }
            previousNode = current
        }

        // 마지막 Chain과 Body 연결
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
            
            // Body와 Chain 사이 거리 제한
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
            limitJoint.maxLength = distance * 1.05
            physicsWorld.add(limitJoint)
            
            // Body의 물리 속성 조정
            bodyPhysics.linearDamping = 0.5
            bodyPhysics.angularDamping = 0.5
        }
    }
}
