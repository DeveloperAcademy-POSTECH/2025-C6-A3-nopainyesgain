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
        GeometryReader { geometry in
            let heightRatio = geometry.size.height / 852
            let isSmallScreen = geometry.size.height < 700
            
            ZStack {
                Group {
                    Image("GreenBackground")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        if isLoading {
                            // 로딩 상태
                            LoadingAlert(type: .short, message: nil)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                        } else if let keyring = keyring {
                            // 키링 로드 성공
                            Spacer()
                                .adaptiveTopPadding()
                            
                            messageSection(keyring: keyring)
                                .padding(.top, isSmallScreen ? -80 : 90)
                            
                            Spacer()
                                .frame(height: isSmallScreen ? 0 : 20)
                            
                            keyringImage(keyring: keyring)
                                .frame(height: isSmallScreen ? 400 : 490)
                                .scaleEffect(heightRatio)
                                .padding(.bottom, isSmallScreen ? 36 : 78)
                            
                            receiveButton
                            
                            Spacer()
                                .adaptiveBottomPadding()
                        } else {
                            // 에러 상태
                            VStack(spacing: 20) {
                                VStack(spacing: 0) {
                                    Image("EmptyViewIcon")
                                        .resizable()
                                        .frame(width: 124, height: 111)
                                    
                                    Text("키링을 불러올 수 없습니다.")
                                        .typography(.suit15R)
                                        .foregroundColor(.black100)
                                        .padding(.vertical, 15)
                                    
                                    Button {
                                        dismiss()
                                    } label: {
                                        Text("닫기")
                                            .typography(.suit15R)
                                            .foregroundColor(.main500)
                                            .padding(.vertical, 15)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .blur(radius: shouldApplyBlur ? 10 : 0)
                .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
                
                if isAccepting || showAcceptCompleteAlert || showInvenFullAlert {
                    Color.black20
                        .ignoresSafeArea()
                        .zIndex(99)
                    
                    if isAccepting {
                        LoadingAlert(type: .short, message: nil)
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                            .zIndex(101)
                    }
                    
                    if showAcceptCompleteAlert {
                        KeychyAlert(
                            type: .addToCollection,
                            message: "키링이 내 보관함에 추가되었어요!",
                            isPresented: $showAcceptCompleteAlert
                        )
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        .zIndex(101)
                    }
                    
                    if showInvenFullAlert {
                        InvenLackPopup(isPresented: $showInvenFullAlert)
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                            .zIndex(100)
                    }
                }
                
                customNavigationBar
                    .blur(radius: shouldApplyBlur ? 15 : 0)
                    .adaptiveTopPadding()
                    .zIndex(0)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            loadKeyringData()
        }
    }
    
    //  블러 적용 여부
    private var shouldApplyBlur: Bool {
        isAccepting ||
        showAcceptCompleteAlert ||
        showInvenFullAlert ||
        false
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
                    .offset(y: -24)
                
                SpriteView(
                    scene: createMiniScene(keyring: keyring),
                    options: [.allowsTransparency]
                )
                .frame(width: 195, height: 300)
                .rotationEffect(.degrees(10))
                .offset(y: -8)
            }
            
            VStack(spacing: 0) {
                Image("PackageFG_T")
                    .resizable()
                    .frame(width: 304, height: 113)
                
                Image("PackageFG_B")
                    .resizable()
                    .frame(width: 304, height: 389)
                    .blendMode(.darken)
                    .offset(y: -12)
            }
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
                .padding(.top, 42)
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
            zoomScale: 2.1,
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
                imageName: "dismiss_gray600",
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
                    .typography(.notosans19B)
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
        
        viewModel.checkInventoryCapacity(userId: receiverId) { hasSpace in
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
            self.viewModel.acceptKeyring(
                postOfficeId: self.postOfficeId,
                keyringId: keyringId,
                senderId: senderId,
                receiverId: receiverId
            ) { success in
                DispatchQueue.main.async {
                    self.isAccepting = false
                
                    if success {
                        self.isAccepted = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                self.showAcceptCompleteAlert = true
                            }
                        }
                    } else {
                        print("키링 수락 실패")
                    }
                }
            }
        }
    }
}

extension KeyringReceiveView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽) - 뒤로가기 버튼
            CloseToolbarButton {
                dismiss()
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        } center: {
            // Center (중앙) - 빈 공간
            Spacer()
        } trailing: {
            // Trailing (오른쪽) - 다음/구매 버튼
            Spacer()
        }
    }
}
