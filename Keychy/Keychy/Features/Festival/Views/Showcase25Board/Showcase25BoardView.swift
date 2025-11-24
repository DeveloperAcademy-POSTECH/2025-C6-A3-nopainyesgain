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
    let gridColumns = 12
    let gridRows = 12
    private let cellAspectRatio: CGFloat = 2.0 / 3.0  // 가로:세로 = 2:3

    // 줌 설정
    private let minZoom: CGFloat = 0.7
    private let maxZoom: CGFloat = 3.0
    private let initialZoom: CGFloat = 0.7

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

            // 출품 확인 팝업
            if showSubmitPopup || showSubmitCompleteAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        if showSubmitPopup {
                            showSubmitPopup = false
                        }
                    }
                    .zIndex(99)

                if showSubmitPopup {
                    SubmitKeyringPopup(
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

                if showSubmitCompleteAlert {
                    SubmitCompleteAlert(isPresented: $showSubmitCompleteAlert)
                        .zIndex(101)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSubmitPopup)
        .animation(.easeInOut(duration: 0.2), value: showSubmitCompleteAlert)
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .modifier(DeleteKeyringAlertModifier(
            showDeleteAlert: $showDeleteAlert,
            gridIndexToDelete: $gridIndexToDelete,
            viewModel: viewModel
        ))
        .onAppear {
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
            Text("SHOWCASE 2025")
                .typography(.notosans17M)
        } trailing: {
            Spacer()
                .frame(width: 44)
        }
    }
    
    // MARK: - GridContent
    
    var gridContent: some View {
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
        .frame(width: gridWidth, height: gridHeight)
    }

}
