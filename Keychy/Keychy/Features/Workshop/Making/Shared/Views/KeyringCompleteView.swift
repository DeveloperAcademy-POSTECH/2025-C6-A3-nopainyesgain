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
    @State var showImageSaved = false
    @State var isCapturingImage = false

    // 씬 인터랙션
    @State var isInteractionEnabled = false
    
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
                    // 키링 씬
                    
                    ZStack(alignment: .center) {
                        keyringScene
                            .frame(height: geometry.size.height * 0.72)
                            .cinematicAppear(delay: 0.2, duration: 0.8, style: .full)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.4)
                        
                        VStack {
                            // 키링 정보
                            keyringInfo
                                .cinematicAppear(delay: 0.6, duration: 0.8, style: .slideUp)
                            
                            // 이미지 저장 버튼
                            saveButton
                                .padding(.top, 10)
                                .cinematicAppear(delay: 1.0, duration: 0.8, style: .fadeIn)
                                .opacity(isCapturingImage ? 0 : 1)
                            //.adaptiveBottomPadding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.8)
                    }
                }
                .blur(radius: showImageSaved ? 15 : 0)

                /// 이미지 저장 완료 alert
                KeychyAlert(
                    type: .imageSave,
                    message: "이미지가 저장되었어요!",
                    isPresented: $showImageSaved
                )

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
        KeyringSceneView(
            viewModel: viewModel,
            backgroundColor: .clear,
            applyWelcomeImpulse: true,
            onSceneReady: {
                // Setup 완료 후 impulse 적용 시간(0.5초) + 여유 시간 대기 후 터치 활성화
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isInteractionEnabled = true
                }
            }
        )
        .frame(maxWidth: .infinity)
        .allowsHitTesting(isInteractionEnabled)
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
                .typography(getBottomPadding(0) == 0 ? .malang24B : .malang26B)
                .foregroundStyle(.black100)
            
            Text(formattedDate(date: viewModel.createdAt))
                .typography(.suit14M)
                .foregroundStyle(.black100)
                .padding(.bottom, 10)
            
            if let nickname = userManager.currentUser?.nickname {
                Text("@\(nickname)")
                    .typography(getBottomPadding(0) == 0 ? .notosans12R : .notosans14R)
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
            .frame(
                width: getBottomPadding(0) == 0 ? 55 : 65,
                height: getBottomPadding(0) == 0 ? 55 : 65
            )
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            
            Text("이미지 저장")
                .typography(.suit13SB)
                .foregroundStyle(.black100)
        }
    }
}
