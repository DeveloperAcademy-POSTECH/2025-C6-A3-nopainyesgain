//
//  KeyringCompleteView.swift
//  KeytschPrototype
//
//  키링 완성 화면
//  - 모든 템플릿에서 공통으로 사용 가능
//

import SwiftUI
import SpriteKit

struct KeyringCompleteView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: VM
    let navigationTitle: String
    
    var userManager: UserManager = UserManager.shared
    
    // 이미지 저장
    @State var checkmarkScale: CGFloat = 0.3
    @State var checkmarkOpacity: Double = 0.0
    @State var showImageSaved = false
    @State var isCapturingImage = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("completeBG2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .cinematicAppear(delay: 0, duration: 0.6, style: .fadeIn)
                    .blur(radius: showImageSaved ? 15 : 0)
                
                VStack(spacing: 0) {
                    Spacer()
                    // 키링 씬 (화면 높이의 60%로 제한)
                    keyringScene
                        .frame(height: geometry.size.height * 0.6)
                        .cinematicAppear(delay: 0.2, duration: 0.8, style: .full)

                    // 키링 정보
                    keyringInfo
                        .cinematicAppear(delay: 0.6, duration: 0.8, style: .slideUp)

                    // 이미지 저장 버튼
                    saveButton
                        .padding(.top, 20)
                        .cinematicAppear(delay: 1.0, duration: 0.8, style: .fadeIn)
                        .opacity(isCapturingImage ? 0 : 1)
                        .adaptiveBottomPadding()
                    
                    Spacer()
                }
                .blur(radius: showImageSaved ? 15 : 0)
                
                if showImageSaved {
                    ImageSaveAlert(checkmarkScale: checkmarkScale)
                        .padding(.bottom, 30)
                }
                
                // 커스텀 네비게이션 바
                customNavigationBar
                    .blur(radius: showImageSaved ? 15 : 0)
                    .opacity(isCapturingImage ? 0 : 1)
                    .adaptiveTopPadding()
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - KeyringScene Section
extension KeyringCompleteView {
    private var keyringScene: some View {
        KeyringSceneView(viewModel: viewModel, backgroundColor: .clear, applyWelcomeImpulse: true)
            .frame(maxWidth: .infinity)
            //.frame(height: 500)
    }
}

//MARK: - 커스텀 네비게이션 바
extension KeyringCompleteView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽)
            CloseToolbarButton {
                viewModel.resetAll()
                router.reset()
            }
            .glassEffect(.regular.interactive(), in: .circle)
        } center: {
            // Center (중앙)
            Text("키링이 완성되었어요!")
                .typography(.suit17B)
                .foregroundStyle(.black100)
        } trailing: {
            // Trailing (오른쪽) - 빈 공간 유지
            Spacer()
                .frame(width: 44, height: 44)
        }
        .cinematicAppear(delay: 0.6, duration: 0.8, style: .fadeIn)
    }
}

// MARK: - 키링 정보 뷰
extension KeyringCompleteView {
    private var keyringInfo: some View {
        VStack(spacing: 0) {
            Text(viewModel.nameText)
                .typography(.notosans24M)
                .foregroundStyle(.black100)
            
            Text(formattedDate(date: viewModel.createdAt))
                .typography(.suit14M)
                .foregroundStyle(.black100)
                .padding(.bottom, 15)
            
            if let nickname = userManager.currentUser?.nickname {
                Text("@\(nickname)")
                    .typography(.notosans15M)
                    .foregroundStyle(.black100)
                    .padding(.vertical, 1)
            }
        }
    }
    
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
}

// MARK: - 저장 버튼
extension KeyringCompleteView {
    private var saveButton: some View {
        VStack(spacing: 9) {
            
            Button(action: {
                captureAndSaveImage()
            }) {
                Image("imageDownload")
            }
            .frame(width: 65, height: 65)
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            
            Text("이미지 저장")
                .typography(.suit13SB)
                .foregroundStyle(.black100)
        }
    }
}


//// MARK: - 프리뷰
//#Preview("iPhone 16 Pro") {
//    KeyringCompleteView(
//        router: NavigationRouter<WorkshopRoute>(),
//        viewModel: AcrylicPhotoVM(),
//        navigationTitle: "키링 완성"
//    )
//}
