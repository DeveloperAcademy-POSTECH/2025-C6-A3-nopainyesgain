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
    @State var collectionViewModel: CollectionViewModel
    let postOfficeId: String

    @State private var viewModel = NotificationGiftViewModel()

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            if viewModel.hasNetworkError {
                networkErrorView
            } else if viewModel.isLoading || viewModel.isCapturing {
                LoadingAlert(type: .short, message: nil)
            } else if let error = viewModel.loadError {
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
                    .opacity(viewModel.showContent ? 1 : 0)
            }
            
            CustomNavigationBar {
                BackToolbarButton {
                    router.pop()
                }
            } center: {
                Text("키링 선물 완료")
            } trailing: {
                Spacer()
                    .frame(width: 44, height: 44)
            }
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .swipeBackGesture(enabled: true)
        .onAppear {
            // 네트워크 체크
            guard NetworkManager.shared.isConnected else {
                viewModel.hasNetworkError = true
                return
            }

            viewModel.fetchGiftData(postOfficeId: postOfficeId, viewModel: collectionViewModel)
            viewModel.markNotificationAsRead(postOfficeId: postOfficeId)

            // 안전장치: 1.5초 후에도 showContent가 false면 강제로 표시
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if !viewModel.showContent {
                    viewModel.showContent = true
                    viewModel.isCapturing = false
                }
            }
        }
        .onChange(of: viewModel.keyring) { oldValue, newValue in
            // 키링 데이터가 로드되면 캐시 이미지 확인
            if let keyring = newValue {
                viewModel.loadCachedImage(keyring: keyring)
            }
        }
    }

    // MARK: - View Components

    /// 네트워크 에러 화면
    private var networkErrorView: some View {
        NoInternetView(onRetry: {
            viewModel.retryFetchGiftData(postOfficeId: postOfficeId, viewModel: collectionViewModel)
        })
        .ignoresSafeArea()
    }

    private var contentView: some View {
        VStack(spacing: 15) {
            Spacer()

            if let keyring = viewModel.keyring {
                keyringImage(keyring: keyring)
                    .scaleEffect(calculateScale())
            }

            // 전달 정보
            VStack(spacing: 4) {
                Text(viewModel.formattedDate)
                    .typography(.suit16M)
                    .foregroundStyle(.gray400)

                HStack(spacing: 0) {
                    Text("\(viewModel.recipientNickname)")
                        .typography(.notosans15SB)
                        .foregroundStyle(.gray400)

                    Text("님에게 전달됨")
                        .typography(.suit16M)
                        .foregroundStyle(.gray400)
                }
            }

            Spacer()
                .frame(maxHeight: 80)
        }
    }

    // MARK: - 수신된 키링 이미지
    private func keyringImage(keyring: Keyring) -> some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Image(.packageBG)
                    .resizable()
                    .frame(width: 280, height: 347)
                    .offset(y: -24)
                
                // 캐시된 이미지가 있으면 사용, 없으면 생성
                if let cachedImage = viewModel.cachedKeyringImage {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 195, height: 300)
                        .scaleEffect(1.05)
                        .rotationEffect(.degrees(10))
                        .offset(y: -22)
                        .shadow(
                            color: Color(hex: "#56522E").opacity(0.35),
                            radius: 6,
                            x: 7,
                            y: 16
                        )
                }
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
                        .typography(.notosans12SB)
                        .foregroundColor(.white100)
                }
                .padding(.leading, 23)
                .padding(.top, 42)
            }
        }
    }
    
    // 기기별 스케일 계산
    private func calculateScale() -> CGFloat {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return 1.0
        }
        
        let screenHeight = window.screen.bounds.height
        
        // SE
        if window.safeAreaInsets.top < 25 {
            return 0.8
        }
        
        // iPhone 14/15
        if screenHeight < 850 {
            return 0.95
        }
        
        // iPhone 16 Pro
        return 1.0
    }
}
