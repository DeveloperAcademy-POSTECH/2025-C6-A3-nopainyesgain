//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//
// 홈 화면 - 메인 뭉치의 키링들을 3D 씬으로 표시

import SwiftUI
import NukeUI
import FirebaseFirestore

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>

    @Bindable var userManager: UserManager

    @State var collectionViewModel: CollectionViewModel

    /// 배경 로드 완료 콜백
    var onBackgroundLoaded: (() -> Void)? = nil

    /// GlassEffect 애니메이션을 위한 네임스페이스
    @Namespace private var unionNamespace

    @State private var viewModel = HomeViewModel()
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // 조건부: 네트워크 에러 화면 또는 정상 콘텐츠
            if viewModel.hasNetworkError {
                networkErrorView
                navigationButtons
            } else {
                // 블러 영역
                ZStack(alignment: .top) {
                    if let bundle = collectionViewModel.selectedBundle,
                       let carabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner),
                       let background = collectionViewModel.selectedBackground {
                        MultiKeyringSceneView(
                            keyringDataList: viewModel.keyringDataList,
                            ringType: .basic,
                            chainType: .basic,
                            backgroundColor: .clear,
                            backgroundImageURL: background.backgroundImage,
                            carabinerBackImageURL: carabiner.backImageURL,
                            carabinerFrontImageURL: carabiner.frontImageURL,
                            carabinerX: carabiner.carabinerX,
                            carabinerY: carabiner.carabinerY,
                            carabinerWidth: carabiner.carabinerWidth,
                            currentCarabinerType: carabiner.type,
                            onBackgroundLoaded: onBackgroundLoaded,
                            onAllKeyringsReady: {
                                viewModel.handleAllKeyringsReady()
                            }
                        )
                        .ignoresSafeArea()
                        /// 씬 재생성 조건을 위한 ID 설정
                        /// 배경, 카라비너, 키링 구성이 변경되면 씬을 완전히 재생성
                        .id("\(background.id ?? "")_\(carabiner.id ?? "")_\(viewModel.keyringDataList.map(\.index).sorted())")
                    } else {
                        // 데이터 로딩 중
                        Color.clear.ignoresSafeArea()
                    }

                    // 네비게이션 버튼 (블러 적용됨)
                    navigationButtons
                }
                .blur(radius: viewModel.isSceneReady ? 0 : 15)

                // 로딩 알림 (씬 준비 전까지 표시)
                if !viewModel.isSceneReady {
                    LoadingAlert(type: .longWithKeychy, message: "키링 뭉치를 불러오고 있어요")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // 알림 리스너 시작
            userManager.startNotificationListener()
        }
        .task {
            // Workshop 배너 백그라운드 prefetch (메인 뭉치 로드를 블로킹하지 않음)
            Task(priority: .background) {
                await WorkshopDataManager.shared.fetchWorkshopBanner()
            }

            // 네트워크 체크
            guard NetworkManager.shared.isConnected else {
                viewModel.hasNetworkError = true
                return
            }

            // 최초 뷰가 나타날 때 메인 뭉치 데이터 로드 (우선순위)
            await viewModel.loadMainBundle(collectionViewModel: collectionViewModel, onBackgroundLoaded: onBackgroundLoaded)
        }
        .onChange(of: viewModel.keyringDataList) { _, _ in
            // 키링 데이터가 변경되면 씬 준비 상태 초기화
            viewModel.handleKeyringDataChange()
        }
        .onChange(of: NetworkManager.shared.isConnected) { oldValue, newValue in
              // 네트워크가 복구되고, 에러 상태였다면 자동 재시도
              if !oldValue && newValue && viewModel.hasNetworkError {
                  Task {
                      await viewModel.retryLoadMainBundle(
                          collectionViewModel: collectionViewModel,
                          onBackgroundLoaded: onBackgroundLoaded
                      )
                  }
              }
          }
        .withToast(position: .tabbar)
    }
}

// MARK: - View Components
extension HomeView {
    /// 네트워크 에러 화면
    private var networkErrorView: some View {
        NoInternetView(topPadding: getSafeAreaTop() + 10, onRetry: {
            Task {
                await viewModel.retryLoadMainBundle(
                    collectionViewModel: collectionViewModel,
                    onBackgroundLoaded: onBackgroundLoaded
                )
            }
        })
        .ignoresSafeArea()
    }

    /// 상단 네비게이션 버튼들
    private var navigationButtons: some View {
        HStack(spacing: 10) {
            Spacer()
            
            // 알림 및 마이페이지 버튼 그룹
            GlassEffectContainer {
                HStack {
                    Button {
                        router.push(.alarmView)
                    } label: {
                        Image(userManager.hasUnreadNotifications ? "alarmSent" : "alarm")
                    }
                    .frame(width: 44, height: 44)
                    .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                    .buttonStyle(.glass)
                    
                    Button {
                        router.push(.myPageView)
                    } label: {
                        Image(.myPageIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        
                    }
                    .frame(width: 44, height: 44)
                    .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                    .buttonStyle(.glass)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

