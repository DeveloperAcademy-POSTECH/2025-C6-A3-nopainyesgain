//
//  KeyringViewModelProtocol+Reset.swift
//  Keychy
//
//  뷰모델 초기화 메서드 기본 구현
//  - 템플릿마다 필요한 경우 override 가능
//

import Foundation

extension KeyringViewModelProtocol {
    // MARK: - 커스터마이징 데이터 초기화
    /// 커스터마이징 데이터만 초기화
    func resetCustomizingData() {
        selectedSound = nil
        selectedParticle = nil
        customSoundURL = nil
        soundId = "none"
        particleId = "none"
        downloadingItemIds.removeAll()
        downloadProgress.removeAll()
    }

    // MARK: - 정보 입력 데이터 초기화
    /// 정보입력뷰에서 뒤로가기 시 호출
    func resetInfoData() {
        nameText = ""
        memoText = ""
        selectedTags.removeAll()
        createdAt = Date()
    }

    // MARK: - 완전 초기화
    /// 모든 데이터 초기화 (완성뷰 dismiss, 커스터마이징뷰 alert 후)
    /// 이미지 선택이 있는 템플릿은 resetAll()을 override하여 resetImageData()도 호출
    func resetAll() {
        resetCustomizingData()
        resetInfoData()
    }
}
