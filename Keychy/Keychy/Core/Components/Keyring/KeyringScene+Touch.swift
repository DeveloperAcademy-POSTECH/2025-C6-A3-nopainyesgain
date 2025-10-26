//
//  KeyringScene+Touch.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/18/25.
//

import SpriteKit

// MARK: - Touch & Swipe Handling
extension KeyringScene {

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        lastTouchLocation = location
        lastTouchTime = touch.timestamp
        swipeStartLocation = location
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // 바디 중앙을 기준으로 스와이프 감지
        if let lastLocation = lastTouchLocation {
            // 스와이프 방향과 속도 계산
            let deltaX = location.x - lastLocation.x
            let deltaY = location.y - lastLocation.y
            let deltaTime = touch.timestamp - lastTouchTime

            if deltaTime > 0 {
                let velocityX = deltaX / CGFloat(deltaTime)
                let velocityY = deltaY / CGFloat(deltaTime)
                let velocity = CGVector(dx: velocityX, dy: velocityY)

                // 바디 중앙 기준으로 좌우 스와이프인지 확인하고 힘 적용
                applySwipeForceToNearbyChains(
                    at: location,
                    velocity: velocity
                )
                
                // 일정 스피드 이상 스와이프 시 이펙트 발사
                let speed = hypot(velocity.dx, velocity.dy)
                if speed > 2500 {
                    applyParticleEffect(for: currentKeyring)
                }
            }
        }

        lastTouchLocation = location
        lastTouchTime = touch.timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let end = touch.location(in: self)

        // 거리 및 속도 계산
        if let start = swipeStartLocation {
            let distance = hypot(end.x - start.x, end.y - start.y)

            // 탭 감지: 거리가 짧으면 사운드 효과 실행
            if distance < 30 {
                if let body = bodyNode, body.contains(end) {
                    applySoundEffect(for: currentKeyring)
                }
            }
        }

        swipeStartLocation = nil
        lastTouchLocation = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        swipeStartLocation = nil
        lastTouchLocation = nil
    }
}
