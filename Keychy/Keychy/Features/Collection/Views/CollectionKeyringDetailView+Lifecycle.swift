//
//  CollectionKeyringDetailView+Lifecycle.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI
import FirebaseFirestore

extension CollectionKeyringDetailView {
    func handleViewAppear() {
        isSheetPresented = true
        isNavigatingDeeper = false
        hideTabBar()
        fetchAuthorName()
    }
    
    func handleViewDisappear() {
        isSheetPresented = false
        if !isNavigatingDeeper {
            showTabBar()
        }
    }
    
    // MARK: - 탭바 제어
    func hideTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = true
            }
        }
    }
    
    func showTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = false
            }
        }
    }
    
    // MARK: - 데이터 불러오기
    func fetchAuthorName() {
        let db = Firestore.firestore()
        
        db.collection("User")
            .document(keyring.authorId)
            .getDocument { snapshot, error in
                if error != nil {
                    self.authorName = "알 수 없음"
                    return
                }
                
                guard let data = snapshot?.data(),
                      let name = data["nickname"] as? String else {
                    self.authorName = "알 수 없음"
                    return
                }
                
                self.authorName = name
            }
    }
    
    func fetchCopyVoucher() {
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
            print("UID를 찾을 수 없습니다")
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("User")
            .document(uid)
            .getDocument { snapshot, error in
                if error != nil {
                    self.copyVoucher = 0
                    return
                }
                
                guard let data = snapshot?.data(),
                      let copyPass = data["copyVoucher"] as? Int else {
                    self.copyVoucher = 0
                    return
                }
                
                self.copyVoucher = copyPass
            }
    }
}
