//
//  KeyringReceiveViewModel.swift
//  Keychy
//
//  Created by Jini on 1/8/26.
//

import SwiftUI

@Observable
class KeyringReceiveViewModel {
    // MARK: - Properties
    var keyring: Keyring?
    var keyringId: String?
    var senderId: String?
    var senderName: String = ""
    var authorName: String = ""
    var isLoading: Bool = true
    var isAccepting: Bool = false
    var isAccepted: Bool = false
    var isAlreadyReceived: Bool = false
    
    // Alert States
    var showAcceptCompleteAlert: Bool = false
    var showInvenFullAlert: Bool = false
    var showAlreadyAcceptedAlert: Bool = false
    var showErrorAlert: Bool = false
    var errorMessage: String = ""
    
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
            
            // receiverId 존재 여부 확인
            if let receiverId = postOfficeData["receiverId"] as? String, !receiverId.isEmpty {
                // 이미 수락된 선물
                print("이미 수락된 선물: receiverId = \(receiverId)")
                self.isAlreadyReceived = true
                self.isLoading = false
                return
            }
            
            self.senderId = senderId
            self.keyringId = keyringId
            
            // 키링 정보 가져오기
            self.loadKeyringInfo(keyringId: keyringId, senderId: senderId)
        }
    }
    
    func loadKeyringInfo(keyringId: String, senderId: String) {
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
    
    // 키링 수락
    func acceptKeyring() {
        guard let receiverId = UserDefaults.standard.string(forKey: "userUID"),
              let keyringId = keyringId,
              let senderId = senderId else {
            print("필요한 정보 누락")
            return
        }
        
        // 수락 전 receiverId 필드 재확인
        collectionViewModel.fetchPostOfficeData(postOfficeId: postOfficeId) { postOfficeData in
            guard let postOfficeData = postOfficeData else {
                print("PostOffice 조회 실패")
                return
            }
            
            // receiverId 필드가 존재하고 값이 있으면 이미 수락된 상태
            if let existingReceiverId = postOfficeData["receiverId"] as? String,
                !existingReceiverId.isEmpty {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.showAlreadyAcceptedAlert = true
                }
                return
            }
            
            // 보관함 용량 확인
            self.checkInventoryAndAccept(
                keyringId: keyringId,
                senderId: senderId,
                receiverId: receiverId
            )

        }
    }
    
    func checkInventoryAndAccept(keyringId: String, senderId: String, receiverId: String) {
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
            
            // 보관함 여유 있음 - 수락 진행
            self.collectionViewModel.acceptKeyring(
                postOfficeId: self.postOfficeId,
                keyringId: keyringId,
                senderId: senderId,
                receiverId: receiverId
            ) { success in
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
    
    private func handleAcceptSuccess() {
        self.isAccepted = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self.showAcceptCompleteAlert = true
            }
        }
    }
    
    private func handleAcceptFailure() {
        print("키링 수락 실패 - 중복 수락 가능성")
        
        // receiverId 확인해서 중복 수락인지 체크
        collectionViewModel.fetchPostOfficeData(postOfficeId: self.postOfficeId) { postOfficeData in
            if let postOfficeData = postOfficeData,
               let existingReceiverId = postOfficeData["receiverId"] as? String,
               !existingReceiverId.isEmpty {
                // 중복 수락
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.showAlreadyAcceptedAlert = true
                }
            } else {
                // 다른 이유로 실패
                print("키링 수락 실패 - 기타 이유")
            }
        }
    }
    
    //  블러 적용 여부
    var shouldApplyBlur: Bool {
        isAccepting ||
        showAcceptCompleteAlert ||
        showInvenFullAlert ||
        showAlreadyAcceptedAlert ||
        false
    }
    
    var backgroundImageName: String {
        // 로딩 중이 아니고, (이미 수락됨 또는 에러 또는 keyring이 nil)
        if !isLoading && (isAlreadyReceived || keyring == nil) {
            return "WhiteBackground"
        }
        return "GreenBackground"
    }
}
