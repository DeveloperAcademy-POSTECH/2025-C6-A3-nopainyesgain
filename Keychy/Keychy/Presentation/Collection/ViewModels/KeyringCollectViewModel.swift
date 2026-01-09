//
//  KeyringCollectViewModel.swift
//  Keychy
//
//  Created by Jini on 1/8/26.
//

import SwiftUI

@Observable
class KeyringCollectViewModel {
    // MARK: - Properties
    var keyring: Keyring?
    var keyringId: String?
    var senderId: String?
    var senderName: String = ""
    var authorName: String = ""
    var isLoading: Bool = true
    var isAccepting: Bool = false
    var isAccepted: Bool = false
    
    // Alert States
    var showAcceptCompleteAlert: Bool = false
    var showInvenFullAlert: Bool = false
    
    private let collectionViewModel: CollectionViewModel
    private let postOfficeId: String
    
    // MARK: - Init
    init(collectionViewModel: CollectionViewModel, postOfficeId: String) {
        self.collectionViewModel = collectionViewModel
        self.postOfficeId = postOfficeId
    }
    
    // MARK: - 데이터 로드
    func loadKeyringData() {
        print("PostOffice 데이터 로드 시작")
        
        collectionViewModel.fetchPostOfficeData(postOfficeId: postOfficeId) { postOfficeData in
            guard let postOfficeData = postOfficeData,
                  let senderId = postOfficeData["senderId"] as? String,
                  let keyringId = postOfficeData["keyringId"] as? String else {
                print("PostOffice 데이터 로드 실패")
                self.isLoading = false
                return
            }
            
            self.senderId = senderId
            self.keyringId = keyringId
            
            // 키링 정보 가져오기
            self.loadKeyringInfo(keyringId: keyringId, senderId: senderId)
        }
    }
    
    private func loadKeyringInfo(keyringId: String, senderId: String) {
        // keyringId로 키링 정보 가져오기
        collectionViewModel.fetchKeyringById(keyringId: keyringId) { fetchedKeyring in
            guard let keyring = fetchedKeyring else {
                print("키링 로드 실패")
                self.isLoading = false
                return
            }
            
            self.keyring = keyring
            
            // authorId로 제작자 이름 로드
            self.collectionViewModel.fetchUserName(userId: keyring.authorId) { name in
                self.authorName = name
            }
            
            // senderId로 발신자 이름 로드
            self.collectionViewModel.fetchUserName(userId: senderId) { name in
                self.senderName = name
                self.isLoading = false
            }
        }
    }
    
    // MARK: - 키링 수령 (배포용)
    func acceptKeyring() {
        guard let receiverId = UserDefaults.standard.string(forKey: "userUID"),
              let keyringId = keyringId,
              let senderId = senderId else {
            print("필요한 정보 누락")
            return
        }
        
        collectionViewModel.checkInventoryCapacity(userId: receiverId) { hasSpace in
            if !hasSpace {
                // 보관함 가득 참
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.showInvenFullAlert = true
                }
                return
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self.isAccepting = true
            }
            
            // 배포용 수령 로직
            self.collectionViewModel.collectKeyring(
                keyringId: keyringId,
                senderId: senderId,
                receiverId: receiverId
            ) { success, errorMessage in
                DispatchQueue.main.async {
                    self.isAccepting = false
                    
                    if success {
                        self.handleAcceptSuccess()
                    } else {
                        self.handleAcceptFailure()
                    }
                }
            }
        }
    }
    
    // MARK: - 성공/실패 Handlers
    private func handleAcceptSuccess() {
        self.isAccepted = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self.showAcceptCompleteAlert = true
            }
        }
    }
    
    private func handleAcceptFailure() {
        print("키링 수령 실패")
        /// TODO: 눈에 보이는 동작 추가 필요 (배포 기능 활용할 때가 되면 기획 후 추가할 것)
    }
    
    // MARK: - Helpers
    //  블러 적용 여부
    var shouldApplyBlur: Bool {
        isAccepting ||
        showAcceptCompleteAlert ||
        showInvenFullAlert ||
        false
    }
    
    var backgroundImageName: ImageResource {
        // 로딩 중이 아니고, (이미 수락됨 또는 에러 또는 keyring이 nil)
        if !isLoading && (keyring == nil) {
            return .whiteBackground
        }
        return .greenBackground
    }
}
