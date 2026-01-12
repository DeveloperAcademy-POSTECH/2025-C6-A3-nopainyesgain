//
//  BundleViewModel+Cache.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//

import FirebaseFirestore

// MARK: - 번들 이미지 캐시 관리
extension BundleViewModel {
    
    /// 캐시에서 번들 이미지를 로드하여 bundleCapturedImage에 설정
    /// - Parameter bundle: 로드할 번들
    /// - Returns: 로드 성공 여부
    @discardableResult
    func loadBundleImageFromCache(bundle: KeyringBundle) -> Bool {
        guard let documentId = bundle.documentId else {
            print("[CollectionViewModel] 번들 documentId가 없습니다.")
            return false
        }
        
        // BundleImageCache에서 이미지 로드
        if let imageData = BundleImageCache.shared.load(for: documentId) {
            self.bundleCapturedImage = imageData
            print("[CollectionViewModel] 캐시에서 번들 이미지 로드 성공: \(documentId)")
            return true
        } else {
            print("[CollectionViewModel] 캐시에 번들 이미지가 없습니다: \(documentId)")
            return false
        }
    }
    
    /// 뷰모델에 저장된 뭉치 이미지를 BundleImageCache에 저장
    func saveBundleImageToCache(
        bundleId: String,
        bundleName: String
    ) {
        guard let imageData = bundleCapturedImage else {
            return
        }
        BundleImageCache.shared.syncBundle(
            id: bundleId,
            name: bundleName,
            imageData: imageData
        )
    }
}
