//
//  BundleDetailUIState.swift
//  Keychy
//
//  Created by 김서현 on 1/8/26.
//

struct BundleDetailUIState {
    var showMenu = false
    var showDeleteAlert = false
    var showDeleteCompleteToast = false
    var showAlreadyMainBundleToast = false
    var showChangeMainBundleAlert = false
    var isMainBundleChange = false
    var isCapturing = false

    mutating func resetOverlays() {
        showMenu = false
        showDeleteAlert = false
        showDeleteCompleteToast = false
        showAlreadyMainBundleToast = false
        showChangeMainBundleAlert = false
        isMainBundleChange = false
    }
}
