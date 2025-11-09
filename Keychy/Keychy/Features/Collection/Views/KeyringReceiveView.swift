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
    @State private var isLoading: Bool = true
    @State private var authorName: String = ""
    
    let keyringId: String
    
    init(viewModel: CollectionViewModel, keyringId: String) {
        self.viewModel = viewModel
        self.keyringId = keyringId
    }
    
    var body: some View {
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
        .background(.white100)
        .onAppear {
            loadKeyringData()
        }
    }
    
    // MARK: - 데이터 로드
    private func loadKeyringData() {
        viewModel.fetchKeyringById(keyringId: keyringId) { fetchedKeyring in
            guard let keyring = fetchedKeyring else {
                isLoading = false
                return
            }
            
            self.keyring = keyring
            
            // 작성자 이름 로드
            viewModel.fetchAuthorName(authorId: keyring.authorId) { name in
                self.authorName = name
                self.isLoading = false
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
                            .typography(.nanum20EB)
                            .foregroundColor(.white100)
                        
                        Text("@\(authorName)")
                            .typography(.suit13SB)
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
            Text("[\(authorName)]가 키링을 선물했어요!")
                .typography(.suit20B)
                .foregroundColor(.black100)
            
            Text("수락하시겠어요?")
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
            // action
            print("키링 수락: \(keyringId)")
            dismiss()
        } label: {
            Text("수락하기")
                .typography(.suit17B)
                .padding(.vertical, 7.5)
                .foregroundStyle(.white100)

        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 1000)
                .fill(.black80)
                .frame(maxWidth: .infinity)
        )
        .padding(.horizontal, 34)
    }
}

//#Preview {
//    KeyringReceiveView(name: "싱싱이")
//}
