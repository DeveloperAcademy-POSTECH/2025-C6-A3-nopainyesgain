//
//  BundleEditView+RestoreSelection.swift
//  Keychy
//
//  Created by 김서현 on 1/13/26.
//
// 뭉치 편집뷰에서 선택했던 항목을 복구하는 메서드를 모아둔 파일입니다.

import SwiftUI

extension BundleEditView {
    // MARK: - 선택 상태 저장/복원
    func saveCurrentSelection() {
        if let bg = bundleVM.newSelectedBackground {
            UserDefaults.standard.set(bg.background.id, forKey: "tempSelectedBackgroundId")
        }
        if let cb = bundleVM.newSelectedCarabiner {
            UserDefaults.standard.set(cb.carabiner.id, forKey: "tempSelectedCarabinerId")
        }
    }
    
    func restoreSelection() {
        restoreBackgroundSelection()
        restoreCarabinerSelection()
    }
    
    func restoreBackgroundSelection() {
        if let savedBackgroundId = UserDefaults.standard.string(forKey: "tempSelectedBackgroundId") {
            if let restoredBackground = bundleVM.backgroundViewData.first(where: { $0.background.id == savedBackgroundId }) {
                bundleVM.newSelectedBackground = restoredBackground
                // 복원 후 삭제
                UserDefaults.standard.removeObject(forKey: "tempSelectedBackgroundId")
            }
        }
    }
    
    func restoreCarabinerSelection() {
        if let savedCarbinerId = UserDefaults.standard.string(forKey: "tempSelectedCarabinerId") {
            if let restoredCarabiner = bundleVM.carabinerViewData.first(where: { $0.carabiner.id == savedCarbinerId }) {
                bundleVM.newSelectedCarabiner = restoredCarabiner
                // 복원 후 삭제
                UserDefaults.standard.removeObject(forKey: "tempSelectedCarabinerId")
            }
        }
    }
}
