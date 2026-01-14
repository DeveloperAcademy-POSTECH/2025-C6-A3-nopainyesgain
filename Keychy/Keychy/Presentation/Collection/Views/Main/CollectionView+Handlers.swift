//
//  CollectionView+Handlers.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

extension CollectionView {
    // MARK: - 데이터 로드
    // 사용자 데이터 로드
    func fetchUserData() {
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
            print("UID를 찾을 수 없습니다")
            return
        }
        
        fetchUserCategories(uid: uid) {
            fetchUserKeyrings(uid: uid)
        }
    }
    
    // 키링 로드
    func fetchUserKeyrings(uid: String) {
        collectionViewModel.fetchUserKeyrings(uid: uid) { success in
            if success {
                print("키링 로드 완료: \(collectionViewModel.keyring.count)개")
                
                // 키링 로드 완료 후 실패한 캐시 재시도
                self.retryFailedCaches()
            } else {
                print("키링 로드 실패")
            }
        }
    }
    
    // 사용자 정보 로드 (태그, 코인, 보관함 용량)
    func fetchUserCategories(uid: String, completion: @escaping () -> Void) {
        collectionViewModel.fetchUserCollectionData(uid: uid) { success in
            if success {
                print("정보 로드 완료")
            } else {
                print("정보 로드 실패")
            }
            completion()
        }
    }
    
    // MARK: - 태그 관리
    // 태그 이름 변경
    func renameCategory() {
        guard !newCategoryName.isEmpty else { return }
        
        // 기존 이름과 같으면 변경 안 함
        guard newCategoryName != renamingCategory else { return }
        
        // 이미 존재하는 태그 이름인지 확인
        if collectionViewModel.tags.contains(newCategoryName) {
            return
        }
        
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
            print("UID를 찾을 수 없습니다")
            return
        }
        
        collectionViewModel.renameTag(
            uid: uid,
            oldName: renamingCategory,
            newName: newCategoryName
        ) { success in
            if success {
                if selectedCategory == renamingCategory {
                    selectedCategory = "전체"
                }
                fetchUserData()
            }
        }
        
        newCategoryName = ""
    }
    
    // 태그 삭제
    func confirmDeleteCategory() {
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
            print("UID를 찾을 수 없습니다")
            return
        }
        
        collectionViewModel.deleteTag(
            uid: uid,
            tagName: deletingCategory
        ) { success in
            if success {
                if selectedCategory == deletingCategory {
                    selectedCategory = "전체"
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    fetchUserData()
                    deletingCategory = ""
                }
            } else {
                showDeleteCompleteAlert = false
                deletingCategory = ""
            }
        }
        
        deletingCategory = ""
    }
    
    // MARK: - 인벤토리 관리
    // 인벤 확장
    func expandInventory() {
        Task {
            let result = await collectionViewModel.purchaseInventoryExpansion(
                userManager: userManager,
                expansionCost: 1000
            )
            
            await MainActor.run {
                switch result {
                case .success:
                    print("인벤토리 확장 성공")
                    
                    // 성공 알림 표시
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPurchaseSuccessAlert = true
                    }
                    
                    // 사용자 데이터 새로고침
                    fetchUserData()
                    
                case .insufficientCoins:
                    print("코인 부족")
                    
                    // 코인 부족 알림 표시
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPurchaseFailAlert = true
                    }
                    
                case .failed(let message):
                    print("구매 실패: \(message)")
                    
                    // 실패 알림 표시
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPurchaseFailAlert = true
                    }
                }
            }
        }
    }
    
    // MARK: - 캐시 프리페칭
    // 캐시 없는 키링들 사전에 캡쳐
    func precacheAllKeyrings() async {
        let uncachedKeyrings = collectionViewModel.keyring.filter { keyring in
            guard let id = keyring.documentId else { return false }
            return !KeyringImageCache.shared.exists(for: id, type: .thumbnail) &&
                    !keyring.isPackaged &&
                    !keyring.isPublished
        }
        
        guard !uncachedKeyrings.isEmpty else { return }
        
        // 배치 처리
        let batchSize = 10
        for i in stride(from: 0, to: uncachedKeyrings.count, by: batchSize) {
            let batch = Array(uncachedKeyrings[i..<min(i + batchSize, uncachedKeyrings.count)])
            
            for keyring in batch {
                await KeyringCacheManager.shared.requestCapture(keyring: keyring)
            }
            
            try? await Task.sleep(for: .seconds(0.5))
        }
    }
    
    // MARK: - 네비게이션
    // 키링 상세뷰로 이동
    func navigateToKeyringDetail(keyring: Keyring) {
        // isNew 상태 업데이트
        if keyring.isNew, let firestoreId = keyring.documentId {
            collectionViewModel.markAsRead(keyringId: firestoreId) { success in
                if success {
                    print("키링 읽음 처리 완료")
                }
            }
        }
        
        // 화면 이동
        if keyring.isPackaged {
            router.push(.collectionKeyringPackageView(keyring))
        } else {
            router.push(.collectionKeyringDetailView(keyring))
        }
    }
    
    // MARK: - 노티피케이션 관리
    // 노티피케이션 설정
    func setupNotifications() {
        // 키보드 노티피케이션 설정 (키보드 높이를 감지해서 검색바 위치 조정)
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
    
    // 노티피케이션 제거
    func removeNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - 캐시 이미지
    func retryFailedCaches() {
        Task(priority: .utility) {
            // 짧은 지연 후 실행 (UI 렌더링 우선)
            try? await Task.sleep(for: .seconds(0.3))
            
            await KeyringCacheManager.shared.retryFailedCaches(
                keyrings: collectionViewModel.keyring
            )
        }
    }
}

