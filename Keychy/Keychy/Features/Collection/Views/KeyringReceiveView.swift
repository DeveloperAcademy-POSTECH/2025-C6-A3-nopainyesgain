//
//  KeyringReceiveView.swift
//  Keychy
//
//  Created by Jini on 11/8/25.
//

import SwiftUI
import SpriteKit

struct KeyringReceiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CollectionViewModel
    @State private var keyring: Keyring?
    @State private var keyringId: String?
    @State private var senderId: String?
    @State private var isLoading: Bool = true
    @State private var senderName: String = ""
    @State private var authorName: String = ""
    @State private var isAccepting: Bool = false
    @State private var isAccepted: Bool = false
    @State private var showAcceptCompleteAlert: Bool = false
    @State private var showInvenFullAlert: Bool = false
    
    let postOfficeId: String
    
    init(viewModel: CollectionViewModel, postOfficeId: String) {
        self.viewModel = viewModel
        self.postOfficeId = postOfficeId
    }
    
    var body: some View {
        ZStack {
            Image("GreenBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                if isLoading {
                    // 로딩 상태
                    ProgressView("로딩 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let keyring = keyring {
                    // 키링 로드 성공
                    headerSection
                    
                    messageSection(keyring: keyring)
                    
                    keyringImage(keyring: keyring)
                    
                    Spacer()
                        .frame(height: 80)
                    
                    receiveButton
                } else {
                    // 에러 상태
                    VStack(spacing: 20) {
                        Text("키링을 불러올 수 없습니다")
                            .typography(.suit16M)
                            .foregroundColor(.gray500)
                        
                        Button("닫기") {
                            dismiss()
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            if showAcceptCompleteAlert || showInvenFullAlert {
                Color.black20
                    .ignoresSafeArea()
                    .zIndex(99)
                
                if showAcceptCompleteAlert {
                    SavedPopup(isPresented: $showAcceptCompleteAlert, message: "키링이 내 보관함에 추가되었어요.")
                        .zIndex(100)
                }
                
                if showInvenFullAlert {
                    InvenLackPopup(
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showInvenFullAlert = false
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                //router.push(.coinCharge) 라우터 연결 필요
                            }
                        }
                    )
                    .zIndex(100)
                }
            }
        }
        .onAppear {
            loadKeyringData()
        }
    }
    
    // MARK: - 데이터 로드
    private func loadKeyringData() {
        print("PostOffice 데이터 로드 시작")
        
        viewModel.fetchPostOfficeData(postOfficeId: postOfficeId) { postOfficeData in
            guard let postOfficeData = postOfficeData,
                  let senderId = postOfficeData["senderId"] as? String,
                  let keyringId = postOfficeData["keyringId"] as? String else { 
                print("PostOffice 데이터 로드 실패")
                isLoading = false
                return
            }
            
            self.senderId = senderId
            self.keyringId = keyringId
            
            // keyringId로 키링 정보 가져오기
            viewModel.fetchKeyringById(keyringId: keyringId) { fetchedKeyring in
                guard let keyring = fetchedKeyring else {
                    print("키링 로드 실패")
                    isLoading = false
                    return
                }
                
                self.keyring = keyring
                
                // authorId로 제작자 이름 로드
                viewModel.fetchUserName(userId: keyring.authorId) { name in
                    self.authorName = name
                }
                
                // senderId로 발신자 이름 로드
                viewModel.fetchUserName(userId: senderId) { name in
                    self.senderName = name
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - 수신된 키링 이미지
    private func keyringImage(keyring: Keyring) -> some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Image("PackageBG")
                    .resizable()
                    .frame(width: 280, height: 347)
                    
                    .offset(y: -15)
                
                SpriteView(
                    scene: createMiniScene(keyring: keyring),
                    options: [.allowsTransparency]
                )
                .frame(width: 195, height: 300)
                .rotationEffect(.degrees(10))
                .offset(y: -7)
            }
            
            Image("PackageFG")
                .resizable()
                .frame(width: 304, height: 490)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(keyring.name)
                            .typography(.notosans20B)
                            .foregroundColor(.white100)
                        
                        Text("@\(authorName)")
                            .typography(.notosans12M)
                            .foregroundColor(.white100)
                    }
                    .padding(.leading, 23)
                    .padding(.top, 58)
                }

        }
    }
    
    private func createMiniScene(keyring: Keyring) -> KeyringCellScene {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)
        
        let scene = KeyringCellScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            targetSize: CGSize(width: 304, height: 490),
            customBackgroundColor: .clear,
            zoomScale: 2.0,
            onLoadingComplete: {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isLoading = false
                    }
                }
            }
        )
        scene.scaleMode = .aspectFill
        return scene
    }
}

// 헤더 (버튼 + 수신 정보)
extension KeyringReceiveView {
    private var headerSection: some View {
        HStack {
            CircleGlassButton(
                imageName: "dismiss",
                action: {
                    dismiss()
                }
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private func messageSection(keyring: Keyring) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Text(senderName)
                    .typography(.notosans20B) // 요기
                    .foregroundColor(.main500)
                
                Text("님이 키링을 선물했어요!")
                    .typography(.suit20B)
                    .foregroundColor(.black100)
            }
            
            Text("수락하면 보관함에 키링이 저장돼요.")
                .typography(.suit16M)
                .foregroundColor(.black100)
                .padding(.bottom, 30)
        }
    }
}

// 하단 버튼
extension KeyringReceiveView {
    private var receiveButton: some View {
        Button {
            if !isAccepted {
                acceptKeyring()
            }
        } label: {
            Text(isAccepted ? "수락됨" : "수락하기")
                .typography(.suit17B)
                .padding(.vertical, 7.5)
                .foregroundStyle(isAccepted ? .gray400 : .white100)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 48)
        .buttonStyle(.glassProminent)
        .tint(isAccepted ? .black20 : .gray600)
        .padding(.horizontal, 34)
        .disabled(isAccepted)
    }
    
    // 수락
    private func acceptKeyring() {
        guard let receiverId = UserDefaults.standard.string(forKey: "userUID"),
              let keyringId = keyringId,
              let senderId = senderId else {
            print("필요한 정보 누락")
            return
        }
        
        isAccepting = true
        
        viewModel.checkInventoryCapacity(userId: receiverId) { hasSpace in
            if !hasSpace {
                // 보관함 가득 참
                self.isAccepting = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.showInvenFullAlert = true
                }
                return
            }
            
            // 보관함 여유 있음 - 수락 진행
            self.viewModel.acceptKeyring(
                postOfficeId: self.postOfficeId,
                keyringId: keyringId,
                senderId: senderId,
                receiverId: receiverId
            ) { success in
                self.isAccepting = false
                
                if success {
                    self.isAccepted = true
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.showAcceptCompleteAlert = true
                    }
                } else {
                    print("키링 수락 실패")
                }
            }
        }
    }
}
