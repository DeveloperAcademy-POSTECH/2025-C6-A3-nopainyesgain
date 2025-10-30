//
//  CarabinerScene+Interaction.swift
//  KeytschPrototype
//
//  Created by Assistant on 10/30/25.
//

import SpriteKit
import UIKit

// MARK: - Touch Interaction & Effects
extension CarabinerScene {
    
    // MARK: - 스와이프 제스처 처리
    
    /// 스와이프 제스처 감지 및 처리
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        lastTouchLocation = location
        lastTouchTime = touch.timestamp
        swipeStartLocation = location
        
        // 터치된 키링 찾기
        if let touchedKeyring = findTouchedKeyring(at: location) {
            handleKeyringTouch(keyring: touchedKeyring, at: location)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let lastLocation = lastTouchLocation else { return }
        
        let currentLocation = touch.location(in: self)
        let deltaX = currentLocation.x - lastLocation.x
        let deltaY = currentLocation.y - lastLocation.y
        
        // 드래그 중인 키링에 미세한 힘 적용
        if let touchedKeyring = findTouchedKeyring(at: currentLocation) {
            applyDragForce(to: touchedKeyring, delta: CGVector(dx: deltaX * 0.1, dy: deltaY * 0.1))
        }
        
        lastTouchLocation = currentLocation
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let startLocation = swipeStartLocation else { return }
        
        let endLocation = touch.location(in: self)
        let swipeVector = CGVector(
            dx: endLocation.x - startLocation.x,
            dy: endLocation.y - startLocation.y
        )
        
        let swipeDistance = hypot(swipeVector.dx, swipeVector.dy)
        let swipeTime = touch.timestamp - lastTouchTime
        
        // 스와이프 강도 계산
        if swipeDistance > 50 && swipeTime < 0.5 {
            let swipeForce = min(swipeDistance / swipeTime, 1000) // 최대 힘 제한
            handleSwipeGesture(force: swipeForce, direction: swipeVector)
        }
        
        // 초기화
        lastTouchLocation = nil
        swipeStartLocation = nil
    }
    
    // MARK: - 키링 찾기 및 상호작용
    
    /// 터치 지점에서 키링 찾기
    private func findTouchedKeyring(at location: CGPoint) -> SKNode? {
        let touchedNode = atPoint(location)
        
        // 터치된 노드가 키링의 자식인지 확인
        var currentNode: SKNode? = touchedNode
        while let node = currentNode {
            if node.name?.hasPrefix("keyring_") == true {
                return node
            }
            currentNode = node.parent
        }
        
        return nil
    }
    
    /// 키링 터치 처리
    private func handleKeyringTouch(keyring: SKNode, at location: CGPoint) {
        // 터치된 키링에 미세한 진동 효과
        let vibrationAction = SKAction.sequence([
            SKAction.rotate(byAngle: 0.05, duration: 0.05),
            SKAction.rotate(byAngle: -0.1, duration: 0.1),
            SKAction.rotate(byAngle: 0.05, duration: 0.05)
        ])
        
        keyring.run(vibrationAction)
    }
    
    /// 드래그 중 키링에 힘 적용
    private func applyDragForce(to keyring: SKNode, delta: CGVector) {
        keyring.enumerateChildNodes(withName: "*") { node, _ in
            if let physicsBody = node.physicsBody, physicsBody.isDynamic {
                physicsBody.applyForce(delta)
            }
        }
    }
    
    /// 스와이프 제스처 처리
    private func handleSwipeGesture(force: CGFloat, direction: CGVector) {
        let normalizedDirection = normalizeVector(direction)
        let swipeForce = CGVector(
            dx: normalizedDirection.dx * force * 0.5,
            dy: normalizedDirection.dy * force * 0.5
        )
        
        // 파티클 효과 (선택사항)
        createSwipeParticleEffect(at: lastTouchLocation ?? CGPoint.zero, direction: normalizedDirection)
    }
    
    // MARK: - 유틸리티 메서드
    
    /// 벡터 정규화
    private func normalizeVector(_ vector: CGVector) -> CGVector {
        let magnitude = hypot(vector.dx, vector.dy)
        guard magnitude > 0 else { return CGVector.zero }
        
        return CGVector(dx: vector.dx / magnitude, dy: vector.dy / magnitude)
    }
    
    /// 스와이프 파티클 효과 생성
    private func createSwipeParticleEffect(at position: CGPoint, direction: CGVector) {
        // 간단한 파티클 효과
        for _ in 0..<10 {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = .systemBlue
            particle.alpha = 0.8
            particle.position = position
            
            addChild(particle)
            
            // 파티클 움직임
            let moveDistance: CGFloat = 50
            let moveVector = CGVector(
                dx: direction.dx * moveDistance + CGFloat.random(in: -20...20),
                dy: direction.dy * moveDistance + CGFloat.random(in: -20...20)
            )
            
            let moveAction = SKAction.move(by: moveVector, duration: 0.5)
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let removeAction = SKAction.removeFromParent()
            
            let sequence = SKAction.sequence([
                SKAction.group([moveAction, fadeAction]),
                removeAction
            ])
            
            particle.run(sequence)
        }
    }
}

// MARK: - Animation Effects
extension CarabinerScene {
    
    /// 키링에 흔들기 애니메이션 적용
    func shakeKeyring(at index: Int, intensity: CGFloat = 1.0) {
        guard let keyring = getKeyring(at: index) else { return }
        
        let shakeAction = SKAction.sequence([
            SKAction.moveBy(x: 5 * intensity, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10 * intensity, y: 0, duration: 0.1),
            SKAction.moveBy(x: 10 * intensity, y: 0, duration: 0.1),
            SKAction.moveBy(x: -5 * intensity, y: 0, duration: 0.05)
        ])
        
        keyring.run(shakeAction)
    }
    
    /// 모든 키링에 흔들기 애니메이션 적용
    func shakeAllKeyrings(intensity: CGFloat = 1.0) {
        for (index, _) in keyrings.enumerated() {
            shakeKeyring(at: index, intensity: intensity)
        }
    }
    
    /// 키링에 탄성 효과 적용
    func bounceKeyring(at index: Int) {
        guard let keyring = getKeyring(at: index) else { return }
        
        let bounceAction = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 0.95, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        
        keyring.run(bounceAction)
    }
    
    /// 카라비너에 회전 애니메이션 적용
    func rotateCarabiner(angle: CGFloat, duration: TimeInterval = 1.0) {
        guard let carabiner = carabinerNode else { return }
        
        let rotateAction = SKAction.rotate(byAngle: angle, duration: duration)
        rotateAction.timingMode = .easeInEaseOut
        
        carabiner.run(rotateAction)
    }
    
    /// 전체 씬에 중력 변경 효과
    func changeGravity(to gravity: CGVector, duration: TimeInterval = 2.0) {
        let currentGravity = physicsWorld.gravity
        let gravitySteps = 60 // 60 steps for smooth transition
        let stepDuration = duration / Double(gravitySteps)
        
        let deltaX = (gravity.dx - currentGravity.dx) / CGFloat(gravitySteps)
        let deltaY = (gravity.dy - currentGravity.dy) / CGFloat(gravitySteps)
        
        var step = 0
        let timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            step += 1
            
            let newGravityX = currentGravity.dx + deltaX * CGFloat(step)
            let newGravityY = currentGravity.dy + deltaY * CGFloat(step)
            
            self.physicsWorld.gravity = CGVector(dx: newGravityX, dy: newGravityY)
            
            if step >= gravitySteps {
                self.physicsWorld.gravity = gravity
                timer.invalidate()
            }
        }
        
        timer.fire()
    }
}

// MARK: - Utility
extension CarabinerScene {
    
    /// 성능 모니터링
    func enablePerformanceMonitoring() {
        view?.showsFPS = true
        view?.showsNodeCount = true
        view?.showsPhysics = true
        view?.showsDrawCount = true
    }
    
    /// 물리 바디 시각화 토글
    func togglePhysicsDebug() {
        view?.showsPhysics.toggle()
    }
}
