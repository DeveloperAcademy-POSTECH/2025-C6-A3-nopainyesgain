//
//  KeyringCellScene+Setup.swift
//  KeytschPrototype
//
//  Created by Jini on 10/26/25.
//

import SpriteKit

// MARK: - Setup & Assembly
extension KeyringCellScene {
    
    // 키링 전체 조립
    func setupKeyring() {
        let centerX: CGFloat = 0
        let topY = originalSize.height * 0.68 - (originalSize.height / 2) // 소수로 높이 위치 조정
        
        // 1. Ring 생성
        let ring = KeyringRingComponent.createNode(from: currentRingType)
        ring.position = CGPoint(x: centerX, y: topY)
        ring.physicsBody?.isDynamic = false
        containerNode.addChild(ring)
        
        // 2. Chain 생성
        let ringHeight = ring.calculateAccumulatedFrame().height
        let ringBottomY = ring.position.y - ringHeight / 2
        let chainStartY = ringBottomY - 2
        let chainSpacing: CGFloat = 16
        let chains = KeyringChainComponent.createLinks(
            from: currentChainType,
            count: 5,
            startPosition: CGPoint(x: centerX, y: chainStartY),
            spacing: chainSpacing
        )
        
        for chain in chains {
            containerNode.addChild(chain)
        }
        
        // 3. Body 생성
        let body: SKNode
        if let image = bodyImage {
            currentBodyType = .customImage(image)
            body = KeyringBodyComponent.createNode(from: currentBodyType)
        } else {
            body = KeyringBodyComponent.createNode(from: currentBodyType)
        }
        
        // Body의 실제 누적 프레임(회전/스케일/하위노드 포함)에 기반
        // 중앙선 기준으로 top을 맞추기 위해 halfHeight를 사용
        let bodyFrame = body.calculateAccumulatedFrame()
        let bodyHalfHeight = bodyFrame.height / 2
        
        // Body 위치 설정 (마지막 체인 아래끝과의 간격을 "바디 중앙선의 top" 기준으로)
        // 마지막 체인의 "중심 Y": 첫 링크 시작점에서 (링크 수 - 1) * spacing 만큼 아래
        let lastChainY = chainStartY - CGFloat(max(chains.count - 1, 0)) * chainSpacing
        
        // 마지막 체인의 실제 높이를 기반으로 "아래 끝 Y" 계산
        let lastLinkHeight: CGFloat = chains.last.map { $0.calculateAccumulatedFrame().height } ?? chainSpacing
        let lastChainBottomY = lastChainY - lastLinkHeight / 2
        
        // 체인과 바디 사이 여유 간격: 화면 비율 또는 바디 크기 비율(중 하나 선택)
        let gap = max(originalSize.height * 0.01, bodyFrame.height * 0.03)
        
        // 바디 중심 Y를 계산:
        // 중앙선 기준 top(= bodyCenterY + bodyHalfHeight)이 lastChainBottomY - gap에 오도록 배치
        let bodyCenterY = lastChainBottomY - gap - bodyHalfHeight
        
        body.position = CGPoint(x: centerX, y: bodyCenterY)
        containerNode.addChild(body)
        
        // 4. 조인트 연결
        connectComponents(ring: ring, chains: chains, body: body)
    }
    
    // 키링 구성 요소들을 Joint로 연결
    func connectComponents(ring: SKShapeNode, chains: [SKShapeNode], body: SKNode) {
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
            
            // scaleFactor로 크기 비율 조정
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
            
            // scaleFactor로 크기 비율 조정
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
            
            // scaleFactor로 크기 비율 조정
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
