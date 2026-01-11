//
//  KeyringCollectView.swift
//  Keychy
//
//  Created by Jini on 11/19/25.
//

import SwiftUI
import SpriteKit

struct KeyringCollectView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: KeyringCollectViewModel
    @State private var scene: KeyringCellScene?
    
    init(viewModel: CollectionViewModel, postOfficeId: String) {
        _viewModel = State(
            initialValue: KeyringCollectViewModel(
                collectionViewModel: viewModel,
                postOfficeId: postOfficeId
            )
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            let heightRatio = geometry.size.height / 852
            let isSmallScreen = geometry.size.height < 700
            
            ZStack {
                backgroundImage
                    .blur(radius: viewModel.shouldApplyBlur ? 10 : 0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.shouldApplyBlur)

                contentView(heightRatio: heightRatio, isSmallScreen: isSmallScreen)
                    .blur(radius: viewModel.shouldApplyBlur ? 10 : 0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.shouldApplyBlur)
                
                alertOverlayView(geometry: geometry)
                
                customNavigationBar
                    .blur(radius: viewModel.shouldApplyBlur ? 15 : 0)
                    .adaptiveTopPadding()
                    .zIndex(0)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.loadKeyringData()
        }
        .onDisappear {
            cleanupScene()
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private func contentView(heightRatio: CGFloat, isSmallScreen: Bool) -> some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                LoadingAlert(type: .short, message: nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if let keyring = viewModel.keyring {
                keyringContentView(
                    keyring: keyring,
                    heightRatio: heightRatio,
                    isSmallScreen: isSmallScreen
                )
                
            } else {
                errorView
            }
        }
    }
    
    private func keyringContentView(keyring: Keyring, heightRatio: CGFloat, isSmallScreen: Bool) -> some View {
        VStack(spacing: 0) {
            messageSection(keyring: keyring)
                .padding(.top, isSmallScreen ? -40 : 90)
            
            Spacer()
                .frame(height: isSmallScreen ? 0 : 20)
            
            keyringImage(keyring: keyring)
                .frame(height: isSmallScreen ? 400 : 490)
                .scaleEffect(heightRatio)
                .padding(.bottom, isSmallScreen ? 36 : 58)
            
            Spacer()
                .frame(minHeight: 0, maxHeight: 20)
            
            receiveButton
            
            Spacer()
                .frame(height: 20)
                .adaptiveBottomPadding()
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                Image(.emptyViewIcon)
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
    
    /// 상단 메세지 섹션
    private func messageSection(keyring: Keyring) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Text(viewModel.senderName)
                    .typography(.notosans19B)
                    .foregroundColor(.main500)
                
                Text("님이 키링을 선물했어요!")
                    .typography(.notosans19M)
                    .foregroundColor(.black100)
            }
            
            Text("수락하면 보관함에 키링이 저장돼요.")
                .typography(.suit16M)
                .foregroundColor(.black100)
                .padding(.bottom, 30)
        }
    }
    
    /// 수신된 키링 이미지
    private func keyringImage(keyring: Keyring) -> some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Image(.packageBG)
                    .resizable()
                    .frame(width: 280, height: 347)
                    .offset(y: -24)
                
                SpriteView(
                    scene: createMiniScene(keyring: keyring),
                    options: [.allowsTransparency]
                )
                .frame(width: 195, height: 300)
                .rotationEffect(.degrees(10))
                .offset(y: -22)
                .shadow(
                    color: Color(hex: "#56522E").opacity(0.35),
                    radius: 6,
                    x: 7,
                    y: 16
                )
            }
            
            VStack(spacing: 0) {
                Image(.packageFGT)
                    .resizable()
                    .frame(width: 304, height: 113)
                
                Image(.packageFGB)
                    .resizable()
                    .frame(width: 304, height: 389)
                    .blendMode(.darken)
                    .opacity(0.55)
                    .offset(y: -12)
            }
            .frame(width: 304, height: 490)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(keyring.name)
                        .typography(.notosans20B)
                        .foregroundColor(.white100)
                    
                    Text("@\(viewModel.authorName)")
                        .typography(.notosans12M)
                        .foregroundColor(.white100)
                }
                .padding(.leading, 23)
                .padding(.top, 42)
            }
        }
    }
    
    private var receiveButton: some View {
        Button {
            if !viewModel.isAccepted {
                viewModel.acceptKeyring()
            }
        } label: {
            Text(viewModel.isAccepted ? "수락됨" : "수락하기")
                .typography(.suit17B)
                .padding(.vertical, 7.5)
                .foregroundStyle(viewModel.isAccepted ? .gray400 : .white100)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 48)
        .buttonStyle(.glassProminent)
        .tint(viewModel.isAccepted ? .black20 : .gray600)
        .padding(.horizontal, 34)
        .disabled(viewModel.isAccepted)
    }
    
    @ViewBuilder
    private var backgroundImage: some View {
        Image(viewModel.backgroundImageName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

extension KeyringCollectView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽) - 뒤로가기 버튼
            CloseToolbarButton {
                dismiss()
            }
        } center: {
            // Center (중앙) - 빈 공간
            Spacer()
        } trailing: {
            // Trailing (오른쪽) - 다음/구매 버튼
            Spacer()
        }
    }
}

// MARK: - Scene 관리
extension KeyringCollectView {
    private func createMiniScene(keyring: Keyring) -> KeyringCellScene {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)

        let scene = KeyringCellScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            templateId: keyring.selectedTemplate,
            targetSize: CGSize(width: 304, height: 490),
            customBackgroundColor: .clear,
            zoomScale: 1.9,
            hookOffsetY: keyring.hookOffsetY,
            chainLength: keyring.chainLength,
            onLoadingComplete: {
                DispatchQueue.main.async {
                    withAnimation {
                        self.viewModel.isLoading = false
                    }
                }
            }
        )
        scene.scaleMode = .aspectFill
        return scene
    }
    
    private func cleanupScene() {
        scene?.removeAllChildren()
        scene?.removeAllActions()
        scene?.physicsWorld.removeAllJoints()
        scene?.view?.presentScene(nil)
        scene = nil
    }
}
