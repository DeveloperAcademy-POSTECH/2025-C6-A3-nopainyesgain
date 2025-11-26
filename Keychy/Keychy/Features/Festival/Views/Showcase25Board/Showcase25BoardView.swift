//
//  Showcase25BoardView.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import SwiftUI
import NukeUI
import FirebaseFirestore

struct Showcase25BoardView: View {
    
    @Bindable var festivalRouter: NavigationRouter<FestivalRoute>
    @Bindable var workshopRouter: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: Showcase25BoardViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    // 위치 기반 체크용
    @State var locationManager = LocationManager()
    
    var onNavigateToWorkshop: ((WorkshopRoute) -> Void)? = nil
    var isFromFestivalTab: Bool = false
    
    // 회수 확인 Alert
    @State var showDeleteAlert = false
    @State var gridIndexToDelete: Int?
    
    // 출품 확인 Popup
    @State var showSubmitPopup = false
    @State var showSubmitCompleteAlert = false
    
    // Heartbeat Timer
    @State private var heartbeatTimer: Timer?
    
    // 키링 선택 시트 그리드 컬럼
    let sheetGridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    let sheetHeightRatio: CGFloat = 0.43
    
    // 그리드 설정
    let gridColumns = 10
    let gridRows = 14
    private let cellAspectRatio: CGFloat = 2.0 / 3.0  // 가로:세로 = 2:3
    
    // 줌 설정
    private let minZoom: CGFloat = 0.4
    private let maxZoom: CGFloat = 3.0
    private let initialZoom: CGFloat = 0.6
    
    // 그리드 전체 크기 계산 (최소 줌 기준)
    var cellWidth: CGFloat {
        screenWidth / 6
    }
    
    var cellHeight: CGFloat {
        cellWidth / cellAspectRatio
    }
    
    var gridWidth: CGFloat {
        cellWidth * CGFloat(gridColumns)
    }
    
    var gridHeight: CGFloat {
        cellHeight * CGFloat(gridRows)
    }
    
    // MARK: - 블러 상태
    private var shouldApplyBlur: Bool {
        showSubmitCompleteAlert
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 메인 컨텐츠
            ZStack(alignment: .top) {
                Color.white100
                    .ignoresSafeArea()
                
                // 확대/축소 가능한 그리드
                ZoomableScrollView(
                    minZoom: minZoom,
                    maxZoom: maxZoom,
                    initialZoom: initialZoom,
                    onZoomChange: { zoom in
                        viewModel.currentZoom = zoom
                    }
                ) {
                    gridContent
                }
                .ignoresSafeArea()
                .blur(radius: shouldApplyBlur ? 10 : 0)
                .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
                
                // 상단 그라데이션 블러 오버레이
                VStack {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .ignoresSafeArea(edges: .top)
                    Spacer()
                }
                .allowsHitTesting(false)
                
                customNavigationBar
                    .blur(radius: shouldApplyBlur ? 15 : 0)
                    .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
            }
            
            // Dim 오버레이 (키링 시트가 열릴 때)
            if viewModel.showKeyringSheet {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSheet()
                    }
                
                // 키링 선택 시트
                keyringSelectionSheet
            }
            
            // 위치 반경 밖에서 +버튼 누르면 뜨는 토스트 팝업
            if viewModel.showOutOfLocationRangeToast {
                VStack {
                    Text("현재 위치에서는 키링을 추가할 수 없어요")
                        .typography(.suit17M)
                        .foregroundStyle(.white100)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 34)
                                .fill(.black50)
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showOutOfLocationRangeToast)
                        .padding(.bottom, 20)
                }
            }
            
            // 출품/회수 확인 팝업
            if showSubmitPopup || showDeleteAlert || showSubmitCompleteAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        if showSubmitPopup {
                            showSubmitPopup = false
                        } else if showDeleteAlert {
                            showDeleteAlert = false
                            gridIndexToDelete = nil
                        }
                    }
                    .zIndex(99)
                
                if showSubmitPopup {
                    ShowcaseConfirmPopup(
                        title: "페스티벌에 키링을 출품할까요?",
                        message: "출품한 키링은 모두에게 공개되고\n종료 전까지 보관함에서 비활성화돼요.",
                        onCancel: {
                            showSubmitPopup = false
                        },
                        onConfirm: {
                            handleSubmitConfirm()
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
                
                if showDeleteAlert {
                    ShowcaseConfirmPopup(
                        title: "키링을 회수할까요?",
                        message: "회수한 키링은 다시 보관함에서\n사용할 수 있어요.",
                        onCancel: {
                            showDeleteAlert = false
                            gridIndexToDelete = nil
                        },
                        onConfirm: {
                            handleDeleteConfirm()
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
                
                if showSubmitCompleteAlert {
                    SubmitCompleteAlert(isPresented: $showSubmitCompleteAlert)
                        .zIndex(101)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSubmitPopup)
        .animation(.easeInOut(duration: 0.2), value: showDeleteAlert)
        .animation(.easeInOut(duration: 0.2), value: showSubmitCompleteAlert)
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // 위치 추적 시작 - FestivalLocationManager에서 가져오기
            if let targetLocation = FestivalLocationManager.shared.currentTargetLocation {
                locationManager.requestPermission()
                locationManager.targetLocations = [targetLocation]
            }
            
            viewModel.startListening()
            Task {
                await viewModel.fetchUserKeyrings()
            }
        }
        .task(id: viewModel.showcaseKeyrings.isEmpty) {
            // 데이터 로드 후 만료된 isEditing 상태 검사
            guard !viewModel.showcaseKeyrings.isEmpty else { return }
            await viewModel.checkAllExpiredEditingStates()
        }
        .onDisappear {
            viewModel.stopListening()
            stopHeartbeat()
            // 위치 추적 중지
            locationManager.stopTracking()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                // 백그라운드 진입 시 시트 닫기 및 수정 상태 해제
                if viewModel.showKeyringSheet {
                    let gridIndex = viewModel.selectedGridIndex
                    viewModel.selectedKeyringForUpload = nil
                    viewModel.showKeyringSheet = false
                    Task {
                        await viewModel.updateIsEditing(at: gridIndex, isEditing: false)
                    }
                    stopHeartbeat()
                }
            }
        }
        .onChange(of: viewModel.showKeyringSheet) { _, isShowing in
            if isShowing {
                startHeartbeat()
                // 시트가 열릴 때마다 유저 키링 목록 새로고침
                Task {
                    await viewModel.fetchUserKeyrings()
                }
            } else {
                stopHeartbeat()
            }
        }
    }
    
    // MARK: - Heartbeat Timer
    
    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await viewModel.refreshEditingTimestamp(at: viewModel.selectedGridIndex)
            }
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    // MARK: - Custom Navigation Bar
    
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                festivalRouter.pop()
            }
        } center: {
            HStack {
                Image(.showcase25Title)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .offset(x: 20)
            }
            
        } trailing: {
            Color.clear
                .frame(width: 44) // leading과 같은 너비로 맞춤
        }
    }
    
    // MARK: - GridContent
    
    var gridContent: some View {
        ZStack {
            // 배경 이미지 (그리드와 함께 움직임)
            //            Image(.showcaseBackground)
            //                .resizable()
            //                .scaledToFill()
            //                .frame(width: gridWidth, height: gridHeight)
            //                .clipped()
            //                .opacity(0.5)
            
            // 그리드
            VStack(spacing: 0) {
                ForEach(0..<gridRows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<gridColumns, id: \.self) { col in
                            let index = row * gridColumns + col
                            gridCell(index: index)
                        }
                    }
                }
            }
        }
        .frame(width: gridWidth, height: gridHeight)
    }
    
}
