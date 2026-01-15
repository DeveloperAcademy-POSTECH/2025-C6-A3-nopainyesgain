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
        isSheetPresented = false
        isNavigatingDeeper = false
        TabBarManager.hide()
        fetchAuthorName()
        
        if keyring.senderId != nil {
            fetchSenderName()
        }
    }
    
    func handleViewDisappear() {
        isSheetPresented = false

        cleanupDetailView()
    }
  
    // MARK: - 정리
    private func cleanupDetailView() {
        // Alert 상태 초기화
        showMenu = false
        showDeleteAlert = false
        showCopyAlert = false
        showPackageAlert = false
        showImageSaved = false
        showUIForCapture = true
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
    
    func fetchSenderName() {
        guard let senderId = keyring.senderId else {
            self.senderName = "알 수 없음"
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("User")
            .document(senderId)
            .getDocument { snapshot, error in
                if error != nil {
                    self.senderName = "알 수 없음"
                    return
                }
                
                guard let data = snapshot?.data(),
                      let name = data["nickname"] as? String else {
                    self.senderName = "알 수 없음"
                    return
                }
                
                self.senderName = name
            }
    }
}
