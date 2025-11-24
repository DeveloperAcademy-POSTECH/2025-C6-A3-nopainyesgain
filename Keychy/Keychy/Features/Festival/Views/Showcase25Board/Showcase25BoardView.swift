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
    private let gridColumns = 12
    private let gridRows = 12
    private let cellAspectRatio: CGFloat = 2.0 / 3.0  // 가로:세로 = 2:3

    // 줌 설정
    private let minZoom: CGFloat = 0.7
    private let maxZoom: CGFloat = 3.0
    private let initialZoom: CGFloat = 0.7

    // 그리드 전체 크기 계산 (최소 줌 기준)
    private var cellWidth: CGFloat {
        screenWidth / 6
    }

    private var cellHeight: CGFloat {
        cellWidth / cellAspectRatio
    }

    private var gridWidth: CGFloat {
        cellWidth * CGFloat(gridColumns)
    }

    private var gridHeight: CGFloat {
        cellHeight * CGFloat(gridRows)
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

                customNavigationBar
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
        }
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

    // MARK: - Grid Content

    private var gridContent: some View {
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

    // MARK: - Grid Cell

    private func gridCell(index: Int) -> some View {
        let keyring = viewModel.keyring(at: index)
        let isMyKeyring = viewModel.isMyKeyring(at: index)
        let isBeingEditedByOthers = viewModel.isBeingEditedByOthers(at: index)

        return ZStack {
            // 셀 배경
            Rectangle()
                .fill(Color.white100)
                .border(Color.gray50, width: 0.5)

            if let keyring = keyring, !keyring.bodyImageURL.isEmpty {
                // 키링 이미지가 있는 경우
                keyringImageView(keyring: keyring, index: index)
            } else if isBeingEditedByOthers, let editingKeyring = keyring {
                // 다른 사람이 수정 중인 경우
                let maskedName = viewModel.maskedNickname(editingKeyring.editingUserNickname)
                VStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("[\(maskedName)]님이\n수정중")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray300)
                        .multilineTextAlignment(.center)
                }
            } else {
                // 키링이 없는 경우 + 버튼
                Button {
                    viewModel.selectedGridIndex = index
                    Task {
                        await viewModel.updateIsEditing(at: index, isEditing: true)
                    }
                    withAnimation(.easeInOut) {
                        viewModel.showKeyringSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white100)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.gray50)
                        )
                }
                .opacity(viewModel.showButtons ? 1 : 0)
                .disabled(!viewModel.showButtons)
                .animation(.easeInOut(duration: 0.2), value: viewModel.showButtons)
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .overlay(alignment: .topTrailing) {
            // 내 키링 표시 (우측 상단)
            if isMyKeyring {
                Circle()
                    .fill(Color.main500.opacity(0.8))
                    .frame(width: 8, height: 8)
                    .padding(6)
            }
        }
    }

    // MARK: - Keyring Image View

    @ViewBuilder
    private func keyringImageView(keyring: ShowcaseFestivalKeyring, index: Int) -> some View {
        let isMyKeyring = viewModel.isMyKeyring(at: index)

        // 캐시된 이미지 확인 (keyringId = Firestore documentId)
        let cachedImageData = KeyringImageCache.shared.load(for: keyring.keyringId)

        let imageView = Group {
            if let imageData = cachedImageData, let uiImage = UIImage(data: imageData) {
                // 캐시된 이미지 사용
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                // 캐시에 없으면 URL로 로드
                LazyImage(url: URL(string: keyring.bodyImageURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.error != nil {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray300)
                    } else {
                        ProgressView()
                    }
                }
            }
        }
        .padding(8)

        // 내 키링인 경우에만 컨텍스트 메뉴 표시
        if isMyKeyring {
            imageView
                .onTapGesture {
                    //testFirestoreKeyringExists(keyringId: keyring.keyringId)
                    fetchAndNavigateToKeyringDetail(keyringId: keyring.keyringId)
                }
                .contextMenu {
                    Button {
                        viewModel.selectedGridIndex = index
                        withAnimation(.easeInOut) {
                            viewModel.showKeyringSheet = true
                        }
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        gridIndexToDelete = index
                        showDeleteAlert = true
                    } label: {
                        Label("회수", systemImage: "arrow.uturn.backward")
                    }
                }
        } else {
            // 남의 키링인 경우 탭 제스처만
            imageView
                .onTapGesture {
                    //testFirestoreKeyringExists(keyringId: keyring.keyringId)
                    fetchAndNavigateToKeyringDetail(keyringId: keyring.keyringId)
                }
        }
    }
}
