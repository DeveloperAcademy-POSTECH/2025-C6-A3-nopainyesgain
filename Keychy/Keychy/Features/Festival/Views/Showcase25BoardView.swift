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
    
    var onNavigateToWorkshop: ((WorkshopRoute) -> Void)? = nil
    var isFromFestivalTab: Bool = false

    // 회수 확인 Alert
    @State private var showDeleteAlert = false
    @State private var gridIndexToDelete: Int?

    // 키링 선택 시트 그리드 컬럼
    private let sheetGridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    private let sheetHeightRatio: CGFloat = 0.43

    // 그리드 설정
    private let gridColumns = 12
    private let gridRows = 12
    private let cellAspectRatio: CGFloat = 2.0 / 3.0  // 가로:세로 = 2:3

    // 줌 설정
    // 최대 축소: 가로 6개 보임 -> 셀 너비 = 화면너비 / 6
    // 최대 확대: 가로 2개 보임 -> 셀 너비 = 화면너비 / 2
    // 확대 배율 = 6 / 2 = 3
    private let minZoom: CGFloat = 0.7
    private let maxZoom: CGFloat = 3.0
    private let initialZoom: CGFloat = 1.5  // 중간 정도로 시작

    // 그리드 전체 크기 계산 (최소 줌 기준)
    private var cellWidth: CGFloat {
        screenWidth / 6  // 최소 줌에서 6개 보임
    }

    private var cellHeight: CGFloat {
        cellWidth / cellAspectRatio  // 2:3 비율
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
        .alert("키링 회수", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {
                gridIndexToDelete = nil
            }
            Button("확인", role: .destructive) {
                if let index = gridIndexToDelete {
                    Task {
                        await viewModel.deleteShowcaseKeyring(at: index)
                    }
                }
                gridIndexToDelete = nil
            }
        } message: {
            Text("정말 키링을 회수하시겠습니까?")
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
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
            } else if isBeingEditedByOthers {
                // 다른 사람이 수정 중인 경우
                VStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("수정 중")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray300)
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

        let imageView = LazyImage(url: URL(string: keyring.bodyImageURL)) { state in
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
        .padding(8)

        // 내 키링인 경우에만 컨텍스트 메뉴 표시
        if isMyKeyring {
            imageView
                .onTapGesture {
                    if let fullKeyring = convertToKeyring(showcaseKeyring: keyring) {
                        router.push(.festivalKeyringDetailView(fullKeyring))
                    }
//                    debugShowcaseKeyring(keyring: keyring)
//                    testFirestoreKeyringExists(keyringId: keyring.keyringId)
//                                        
//                    fetchAndNavigateToKeyringDetail(keyringId: keyring.keyringId)
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
                    if let fullKeyring = convertToKeyring(showcaseKeyring: keyring) {
                        router.push(.festivalKeyringDetailView(fullKeyring))
                    }
                    
//                    debugShowcaseKeyring(keyring: keyring)
//                    testFirestoreKeyringExists(keyringId: keyring.keyringId)
//                                        
//                    fetchAndNavigateToKeyringDetail(keyringId: keyring.keyringId)
                }
        }
    }

    // MARK: - Custom Navigation Bar

    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                festivalRouter.pop()
            }
        } center: {
            Text("쇼케이스 2025")
                .typography(.notosans17M)
        } trailing: {
            Button {
                // Festival에서 Workshop으로 가는 경우 플래그 설정
                viewModel.isFromFestivalTab = true
                
                // Workshop에서 완료 후 다시 돌아올 콜백 설정
                viewModel.onKeyringCompleteFromFestival = { workshopRouter in
                    // Workshop router를 reset하고 showcase25BoardView로 이동
                    workshopRouter.reset()
                    workshopRouter.push(.showcase25BoardView)
                }
                
                onNavigateToWorkshop?(.acrylicPhotoPreview)
            } label: {
                Image(.appIcon)
                    .resizable()
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Keyring Selection Sheet

    private var keyringSelectionSheet: some View {
        VStack(spacing: 18) {
            // 상단 바: 취소 / 타이틀 / 완료
            HStack {
                // 취소 버튼
                Button {
                    dismissSheet()
                } label: {
                    Text("취소")
                        .typography(.suit15R)
                        .foregroundStyle(.gray500)
                }

                Spacer()

                Text("키링 선택")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)

                Spacer()

                // 완료 버튼
                Button {
                    confirmSelection()
                } label: {
                    Text("완료")
                        .typography(.suit15M)
                        .foregroundStyle(viewModel.selectedKeyringForUpload != nil ? .main500 : .gray300)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedKeyringForUpload == nil)
            }

            if viewModel.userKeyrings.isEmpty {
                // 키링이 없는 경우
                VStack {
                    Image(.emptyViewIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 77)
                    Text("공방에서 키링을 만들 수 있어요")
                        .typography(.suit15R)
                        .foregroundStyle(.black100)
                        .padding(.vertical, 15)
                }
                .padding(.bottom, 77)
                .padding(.top, 62)
                .frame(maxWidth: .infinity)
            } else {
                // 키링 목록
                ScrollView {
                    LazyVGrid(columns: sheetGridColumns, spacing: 10) {
                        ForEach(viewModel.userKeyrings, id: \.self) { keyring in
                            keyringCell(keyring: keyring)
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
        .frame(maxWidth: .infinity)
        .frame(height: screenHeight * sheetHeightRatio)
        .glassEffect(.regular, in: .rect)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .transition(.move(edge: .bottom))
    }

    // MARK: - Sheet Actions

    private func dismissSheet() {
        let gridIndex = viewModel.selectedGridIndex
        viewModel.selectedKeyringForUpload = nil
        withAnimation(.easeInOut) {
            viewModel.showKeyringSheet = false
        }
        // isEditing 상태 해제
        Task {
            await viewModel.updateIsEditing(at: gridIndex, isEditing: false)
        }
    }

    private func confirmSelection() {
        guard let keyring = viewModel.selectedKeyringForUpload else { return }
        let gridIndex = viewModel.selectedGridIndex

        // 시트 먼저 닫기
        viewModel.selectedKeyringForUpload = nil
        withAnimation(.easeInOut) {
            viewModel.showKeyringSheet = false
        }

        // 업로드는 백그라운드에서 진행
        Task {
            await viewModel.addOrUpdateShowcaseKeyring(
                at: gridIndex,
                with: keyring
            )
        }
    }

    // MARK: - Keyring Cell

    private func keyringCell(keyring: Keyring) -> some View {
        let isSelected = viewModel.selectedKeyringForUpload?.id == keyring.id

        return Button {
            // 선택 상태 토글
            if isSelected {
                viewModel.selectedKeyringForUpload = nil
            } else {
                viewModel.selectedKeyringForUpload = keyring
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    CollectionCellView(keyring: keyring)
                        .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                        .cornerRadius(10)

                    // 선택 표시
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.main500, lineWidth: 3)
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                    }
                }

                Text(keyring.name)
                    .typography(isSelected ? .notosans14SB : .notosans14M)
                    .foregroundStyle(isSelected ? .main500 : .black100)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .disabled(keyring.status == .packaged || keyring.status == .published)
    }
    
    // MARK: - Fetch Keyring from Firestore and Navigate
    
    func fetchAndNavigateToKeyringDetail(keyringId: String) {
        guard keyringId != "none" else {
            print("유효하지 않은 keyringId")
            return
        }
        
        Task {
            do {
                // 1. Firestore에서 실제 Keyring 문서 가져오기
                let document = try await Firestore.firestore()
                    .collection("Keyring")
                    .document(keyringId)
                    .getDocument()
                
                guard document.exists, let data = document.data() else {
                    print("Keyring 문서를 찾을 수 없습니다")
                    return
                }
                
                // 2. Keyring 모델로 변환
                if let keyring = Keyring(documentId: document.documentID, data: data) {
                    // 3. DetailView로 이동 (Main thread에서 실행)
                    await MainActor.run {
                        router.push(.festivalKeyringDetailView(keyring))
                    }
                } else {
                    print("Keyring 변환 실패")
                }
            } catch {
                print("Keyring 데이터 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }
    
    private func convertToKeyring(showcaseKeyring: ShowcaseFestivalKeyring) -> Keyring? {
        // ShowcaseFestivalKeyring의 데이터를 사용하여 Keyring 객체 생성
        // 필요한 필드들을 매핑
        
        return Keyring(
            name: showcaseKeyring.name,
            bodyImage: showcaseKeyring.bodyImageURL,
            soundId: showcaseKeyring.soundId,
            particleId: showcaseKeyring.particleId,
            memo: showcaseKeyring.memo == "none" ? nil : showcaseKeyring.memo,
            tags: [],
            createdAt: showcaseKeyring.createdAt,
            authorId: showcaseKeyring.authorId,
            selectedTemplate: "Unknown",
            selectedRing: "basicRing",
            selectedChain: "basicChain1",
            originalId: nil,
            chainLength: 5,
            isEditable: false,
            isNew: false,
            senderId: nil,
            receivedAt: nil,
            hookOffsetY: nil
        )
    }
    
    func debugShowcaseKeyring(keyring: ShowcaseFestivalKeyring) {
        print("""
        
        📋 ShowcaseFestivalKeyring 디버그 정보
        =====================================
        id (document ID): \(keyring.id)
        keyringId: \(keyring.keyringId)
        name: \(keyring.name)
        authorId: \(keyring.authorId)
        bodyImageURL: \(keyring.bodyImageURL)
        soundId: \(keyring.soundId)
        particleId: \(keyring.particleId)
        =====================================
        
        """)
    }
    
    func testFirestoreKeyringExists(keyringId: String) {
        Task {
            do {
                let document = try await Firestore.firestore()
                    .collection("Keyring")
                    .document(keyringId)
                    .getDocument()
                
                print("""
                
                🔍 Firestore 조회 테스트
                =====================================
                keyringId: \(keyringId)
                document.exists: \(document.exists)
                documentID: \(document.documentID)
                data 필드 개수: \(document.data()?.keys.count ?? 0)
                =====================================
                
                """)
                
                if let data = document.data() {
                    print("📦 문서 필드:")
                    for (key, value) in data {
                        print("  - \(key): \(value)")
                    }
                }
            } catch {
                print("❌ 테스트 실패: \(error)")
            }
        }
    }
}
