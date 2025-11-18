//
//  NotificationGiftView.swift
//  Keychy
//
//  Created on 11/18/25.
//

import SwiftUI
import FirebaseFirestore
import SpriteKit

struct NotificationGiftView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    let postOfficeId: String

    @State private var keyringId: String = ""
    @State private var keyringName: String = ""
    @State private var recipientNickname: String = ""
    @State private var authorName: String = ""
    @State private var completedDate: Date = Date()
    @State private var isLoading: Bool = true
    @State private var loadError: String?
    @State private var keyring: Keyring?

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            if isLoading {
                LoadingAlert(type: .short, message: nil)
            } else if let error = loadError {
                VStack {
                    Text("선물 정보를 불러올 수 없습니다")
                        .typography(.suit16B)
                    Text(error)
                        .typography(.suit13M)
                        .foregroundStyle(.gray400)
                        .padding(.top, 4)
                }
            } else {
                contentView
            }
        }
        .navigationTitle("키링 선물 완료")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backBtn
        }
        .onAppear {
            fetchGiftData()
        }
    }

    private var contentView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let keyring = keyring {
                keyringImage(keyring: keyring)
            }

            // 전달 정보
            VStack(spacing: 4) {
                Text(formattedDate)
                    .typography(.suit16M)
                    .foregroundStyle(.gray400)

                HStack(spacing: 0) {
                    Text("\(recipientNickname)")
                        .typography(.notosans15SB)
                        .foregroundStyle(.gray400)
                    
                    Text("님에게 전달됨")
                        .typography(.suit16M)
                        .foregroundStyle(.gray400)
                }
            }
            Spacer()
        }
    }

    private var backBtn: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CloseToolbarButton {
                router.pop()
            }
            .frame(width: 32, height: 32)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: completedDate)
    }

    private func fetchGiftData() {
        isLoading = true

        // 1. PostOffice 조회
        db.collection("PostOffice").document(postOfficeId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let keyringId = data["keyringId"] as? String,
                  let receiverId = data["receiverId"] as? String,
                  let endedTimestamp = data["endedAt"] as? Timestamp else {
                self.loadError = "선물 정보를 찾을 수 없습니다"
                self.isLoading = false
                return
            }

            self.completedDate = endedTimestamp.dateValue()
            self.keyringId = keyringId

            viewModel.fetchKeyringById(keyringId: keyringId) { fetchedKeyring in
                guard let keyring = fetchedKeyring else {
                    self.loadError = "키링 정보를 찾을 수 없습니다"
                    self.isLoading = false
                    return
                }

                self.keyring = keyring
                self.keyringName = keyring.name

                // 제작자 이름 로드
                viewModel.fetchUserName(userId: keyring.authorId) { name in
                    self.authorName = name
                }

                // 수신자 닉네임 로드
                viewModel.fetchUserName(userId: receiverId) { nickname in
                    self.recipientNickname = nickname
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
                        .typography(.notosans12SB)
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
            hookOffsetY: keyring.hookOffsetY,
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
