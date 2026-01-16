//
//  KeyringCustomizingView+Cart.swift
//  Keychy
//
//  장바구니 관리 로직
//

import Foundation

// MARK: - Cart Management
extension KeyringCustomizingView {
    /// 사운드를 장바구니에 추가 (사운드는 1개만 담을 수 있음)
    func addSoundToCart(_ sound: Sound) {
        // 기존 사운드가 있다면 제거
        cartItems.removeAll { $0.type == .sound }

        // 새 사운드 추가
        let item = EffectItem(sound: sound)
        cartItems.append(item)
    }

    /// 파티클을 장바구니에 추가 (파티클은 1개만 담을 수 있음)
    func addParticleToCart(_ particle: Particle) {
        // 기존 파티클이 있다면 제거
        cartItems.removeAll { $0.type == .particle }

        // 새 파티클 추가
        let item = EffectItem(particle: particle)
        cartItems.append(item)
    }

    /// 장바구니에서 아이템 제거
    func removeFromCart(_ itemId: String) {
        cartItems.removeAll { $0.id == itemId }
    }

    /// 장바구니 비우기
    func clearCart() {
        cartItems.removeAll()
    }

    /// 총 가격 계산
    var totalCartPrice: Int {
        cartItems.reduce(0) { $0 + $1.price }
    }

    /// 장바구니에 아이템이 있는지 확인
    var hasCartItems: Bool {
        !cartItems.isEmpty
    }

    /// 특정 아이템이 장바구니에 있는지 확인
    func isInCart(_ itemId: String) -> Bool {
        cartItems.contains(where: { $0.id == itemId })
    }
}
