//
//  CarabinerScene+Interaction.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/30/25.
//

import SpriteKit
import UIKit

// MARK: - Touch Interaction & Effects (KeyringScene 스타일)
extension CarabinerScene {
    
    // MARK: - 스와이프 제스처 처리 (KeyringScene과 동일)
    
    /// Chain과 Body에 스와이프 영향 적용 (바디 중앙 기준 좌우 스와이프)
    func applySwipeForceToNearbyChains(at location: CGPoint, velocity: CGVector) {
        // 모든 키링에 대해 스와이프 적용
        for keyring in keyrings {
            applySwipeForceToKeyring(keyring: keyring, velocity: velocity)
        }
    }
    
    /// 개별 키링에 스와이프 힘 적용 (적당한 강도로 조정)
    private func applySwipeForceToKeyring(keyring: SKNode, velocity: CGVector) {
        // 힘의 강도를 적당하게 조정
        let forceMagnitude: CGFloat = 0.5  // 1.5에서 0.6으로 줄임 (적당한 강도)
        
        // 키링의 체인들을 찾아서 힘 적용
        var chainNodes: [SKSpriteNode] = []
        var ringNode: SKSpriteNode?
        
        // 현재 씬에서 같은 인덱스의 구성 요소들 찾기
        if let keyringName = keyring.name,
           keyringName.contains("keyring_") {
            
            // 키링 이름에서 인덱스 추출
            let components = keyringName.components(separatedBy: "_")
            if components.count >= 3, let index = Int(components[1]) {
                
                // 해당 인덱스의 링 찾기
                enumerateChildNodes(withName: "keyring_\(index)_ring") { node, _ in
                    if let ring = node as? SKSpriteNode {
                        ringNode = ring
                    }
                }
                
                // 해당 인덱스의 체인들 찾기
                enumerateChildNodes(withName: "keyring_\(index)_chain_*") { node, _ in
                    if let chainNode = node as? SKSpriteNode {
                        chainNodes.append(chainNode)
                    }
                }
            }
        }
        
        print("🎯 키링 힘 적용: \(chainNodes.count)개 체인, 링=\(ringNode != nil), 바디=\(keyring.name ?? "nil")")
        
        // 체인에 적당한 힘 적용
        for chainNode in chainNodes {
            let chainForce = CGVector(
                dx: velocity.dx * forceMagnitude * 0.4,  // 0.8에서 0.4로 줄임
                dy: velocity.dy * forceMagnitude * 0.4
            )
            chainNode.physicsBody?.applyImpulse(chainForce)
            
            // 회전 효과도 줄임
            let angularImpulse = velocity.dx * 0.0005  // 0.001에서 0.0005로 줄임
            chainNode.physicsBody?.applyAngularImpulse(angularImpulse)
        }
        
        // Body에도 적당한 힘 적용
        let bodyForce = CGVector(
            dx: velocity.dx * forceMagnitude * 0.5,  // 1.0에서 0.5로 줄임
            dy: velocity.dy * forceMagnitude * 0.5
        )
        keyring.physicsBody?.applyImpulse(bodyForce)
        
        // 바디 회전 효과도 줄임
        let bodyAngularImpulse = velocity.dx * 0.001  // 0.002에서 0.001로 줄임
        keyring.physicsBody?.applyAngularImpulse(bodyAngularImpulse)
    }
    
    /// 스와이프 제스처 감지 및 처리 (KeyringScene 스타일)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        lastTouchLocation = location
        lastTouchTime = touch.timestamp
        swipeStartLocation = location
        
        print("🎯 터치 시작: location=\(location)")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let lastLocation = lastTouchLocation else { return }
        
        let currentLocation = touch.location(in: self)
        
        // 스와이프 감지 및 힘 적용 로직(KeyringScene와 동일)
        let deltaX = currentLocation.x - lastLocation.x
        let deltaY = currentLocation.y - lastLocation.y
        let deltaTime = touch.timestamp - lastTouchTime
        
        if deltaTime > 0 {
            let velocityX = deltaX / CGFloat(deltaTime)
            let velocityY = deltaY / CGFloat(deltaTime)
            let velocity = CGVector(dx: velocityX, dy: velocityY)
            
            // 실시간으로 스와이프 힘 적용 (KeyringScene과 동일)
            applySwipeForceToNearbyChains(at: currentLocation, velocity: velocity)
            
            print("🎯 스와이프 힘 적용: velocity=(\(velocityX), \(velocityY))")
        }
        
        lastTouchLocation = currentLocation
        lastTouchTime = touch.timestamp
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
        
        // 스와이프 감지 (KeyringScene과 동일한 조건)
        if swipeDistance > 50 && swipeTime < 0.5 {
            applySwipeForceToNearbyChains(at: endLocation, velocity: swipeVector)
        }
        
        // 초기화
        lastTouchLocation = nil
        swipeStartLocation = nil
    }
}

// MARK: - Animation Effects (KeyringScene 스타일)
extension CarabinerScene {
    
    /// 모든 키링에 흔들기 애니메이션 적용
    func shakeAllKeyrings(intensity: CGFloat = 1.0) {
        for keyring in keyrings {
            let shakeAction = SKAction.sequence([
                SKAction.moveBy(x: 5 * intensity, y: 0, duration: 0.05),
                SKAction.moveBy(x: -10 * intensity, y: 0, duration: 0.1),
                SKAction.moveBy(x: 10 * intensity, y: 0, duration: 0.1),
                SKAction.moveBy(x: -5 * intensity, y: 0, duration: 0.05)
            ])
            keyring.run(shakeAction)
        }
    }
    
    /// 카라비너에 회전 애니메이션 적용 (KeyringScene 스타일)
    func rotateCarabiner(angle: CGFloat, duration: TimeInterval = 1.0) {
        guard let carabiner = carabinerNode else { return }
        
        let rotateAction = SKAction.rotate(byAngle: angle, duration: duration)
        rotateAction.timingMode = .easeInEaseOut
        
        carabiner.run(rotateAction)
    }
}

// MARK: - Utility (KeyringScene 스타일)
extension CarabinerScene {
    
    /// 성능 모니터링 (개발용)
    func enablePerformanceMonitoring() {
        view?.showsFPS = true
        view?.showsNodeCount = true
        view?.showsPhysics = true
        view?.showsDrawCount = true
    }
    
    /// 물리 바디 시각화 토글 (개발용)
    func togglePhysicsDebug() {
        view?.showsPhysics.toggle()
    }
}
