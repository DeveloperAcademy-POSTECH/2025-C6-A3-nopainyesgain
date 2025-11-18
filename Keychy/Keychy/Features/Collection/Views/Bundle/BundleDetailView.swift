//
//  BundleDetailView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//
// 키링 뭉치 상세보기 화면 - 선택한 뭉치의 키링들을 3D 씬으로 표시

import SwiftUI
import NukeUI
import FirebaseFirestore

struct BundleDetailView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var viewModel: CollectionViewModel
    
    // MARK: - State Management
    @State private var showMenu: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteCompleteToast: Bool = false
    @State private var showChangeMainBundleAlert: Bool = false
    @State var isCapturing: Bool = false
    @State private var isNavigatingDeeper: Bool = true
    
    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []
    
    /// 씬 준비 완료 여부
    @State private var isSceneReady = false
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                if let bundle = viewModel.selectedBundle,
                   let carabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner),
                   let background = viewModel.selectedBackground {
                    
                    MultiKeyringSceneView(
                        keyringDataList: keyringDataList,
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
                        onAllKeyringsReady: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isSceneReady = true
                            }
                        }
                    )
                    .animation(.easeInOut(duration: 0.3), value: isSceneReady)
                    /// 씬 재생성 조건을 위한 ID 설정
                    /// 배경, 카라비너, 키링 구성이 변경되면 씬을 완전히 재생성
                    .id("\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map(\.index).sorted())")
                    
                    // 하단 섹션을 ZStack 안에서 직접 배치
                    VStack {
                        Spacer()
                        bottomSection
                    }
                    
                    if showMenu {
                        HStack {
                            Spacer()
                            VStack {
                                BundleMenu(
                                    onNameEdit: {
                                        showMenu = false
                                        isNavigatingDeeper = true
                                        router.push(.bundleNameEditView)
                                    },
                                    onEdit: {
                                        showMenu = false
                                        isNavigatingDeeper = true
                                        router.push(.bundleEditView)
                                    },
                                    onDelete: {
                                        showMenu = false
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showDeleteAlert = true
                                        }
                                    },
                                    isMain: bundle.isMain
                                )
                                .padding(.trailing, 16)
                                .padding(.top, 8)
                                
                                Spacer()
                            }
                        }
                        .padding(.top, 60)
                        .zIndex(50)
                        .allowsHitTesting(true)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showMenu = false
                            }
                        }
                    }
                }
                customnavigationBar
            }
            .blur(radius: isSceneReady ? 0 : 15)
            
            if !isSceneReady {
                Color.black20
                    .ignoresSafeArea()
                
                LoadingAlert(type: .longWithKeychy, message: "뭉치를 불러오고 있어요")
                    .zIndex(200)
            }
            
            capturingOverlay
                .opacity(isCapturing ? 1 : 0)
            
            
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // 다른 뷰에서 돌아왔을 때 씬이 준비되지 않았다면 다시 로드
            if !isSceneReady {
                Task {
                    await loadBundleData()
                }
            }
            isNavigatingDeeper = false
            viewModel.hideTabBar()
        }
        .onDisappear {
            // 뷰가 사라질 때 씬 준비 상태 초기화
            isSceneReady = false
        }
        .task {
            // 최초 뷰가 나타날 때 뭉치 데이터 로드
            await loadBundleData()
        }
        .onChange(of: keyringDataList) { _, _ in
            // 키링 데이터가 변경되면 씬 준비 상태 초기화
            withAnimation(.easeIn(duration: 0.2)) {
                isSceneReady = false
            }
        }
        .overlay {
            ZStack(alignment: .center) {
                // 삭제 확인 Alert
                if showDeleteAlert {
                    Color.black40
                        .ignoresSafeArea()
                    if let bundle = viewModel.selectedBundle {
                        DeletePopup(
                            title: "\(bundle.name)\n삭제하시겠어요?",
                            message: "삭제한 뭉치는 복구할 수 없습니다",
                            onCancel: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showDeleteAlert = false
                                }
                            },
                            onConfirm: {
                                Task {
                                    await deleteBundle()
                                }
                            }
                        )
                    }
                }
                if showDeleteCompleteToast {
                    Color.black40
                        .ignoresSafeArea()
                    DeleteCompletePopup(isPresented: $showDeleteCompleteToast)
                        .zIndex(100)
                }
                
                if showChangeMainBundleAlert {
                    Color.black40
                        .ignoresSafeArea()
                    changeMainBundleAlert
                        .padding(.horizontal, 51)
                }
            }
        }
    }
}

// MARK: - Data Loading
extension BundleDetailView {
    /// 선택된 뭉치 데이터를 로드하고 뷰 상태를 초기화
    /// 1. 배경 및 카라비너 데이터 로드
    /// 2. 선택된 뭉치의 배경과 카라비너 설정
    /// 3. 선택된 뭉치의 키링들을 Firestore에서 가져와 KeyringData 리스트 생성
    @MainActor
    private func loadBundleData() async {
        // 1. 배경 및 카라비너 데이터 로드
        await viewModel.loadBackgroundsAndCarabiners()
        
        // 2. 선택된 뭉치의 배경과 카라비너 설정
        guard let bundle = viewModel.selectedBundle else { return }
        viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
        viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)
        
        // 3. 키링 데이터 생성
        guard let carabiner = viewModel.selectedCarabiner else { return }
        keyringDataList = await viewModel.createKeyringDataList(bundle: bundle, carabiner: carabiner)
    }
    
    /// 뭉치 삭제
    @MainActor
    private func deleteBundle() async {
        guard let bundle = viewModel.selectedBundle,
              let documentId = bundle.documentId else {
            showDeleteAlert = false
            return
        }
        
        do {
            // 1. 삭제 확인 Alert 닫기
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDeleteAlert = false
            }
            
            let db = Firestore.firestore()
            
            // 2. Firebase에서 문서 삭제
            try await db.collection("KeyringBundle").document(documentId).delete()
            
            // 3. 로컬 배열에서도 제거
            viewModel.bundles.removeAll { $0.documentId == documentId }
            
            // 5. 삭제 완료 팝업 표시
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDeleteCompleteToast = true
            }
            
            // 6. 1.5초 후 팝업 닫고 이전 화면으로 이동
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDeleteCompleteToast = false
            }
            
            // 7. 애니메이션 완료 대기 후 화면 이동
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초
            
            router.pop()
            
        } catch {
            print("[BundleDetail] 뭉치 삭제 실패: \(error.localizedDescription)")
            showDeleteAlert = false
        }
    }
}

// MARK: - 커스텀 네비게이션 바
extension BundleDetailView {
    private var customnavigationBar: some View {
        CustomNavigationBar {
            //Leading(왼쪽)
            BackToolbarButton {
                router.pop()
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular, in: .circle)
        } center: {
        } trailing: {
            // Trailing (오른쪽)
            MenuToolbarButton {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular, in: .circle)
        }
        
    }
}

// MARK: - View Components
extension BundleDetailView {
    
    /// 하단 정보 섹션 - 핀 버튼, 뭉치 이름/개수, 다운로드 버튼
    private var bottomSection: some View {
        VStack {
            Spacer()
            HStack {
                pinButton
                Spacer()
                if let bundle = viewModel.selectedBundle {
                    if bundle.isMain {
                        Text("대표 뭉치 설정 중")
                            .typography(.suit16M)
                            .foregroundStyle(.white100)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.main500)
                            )
                    }
                }
                Spacer()
                downloadImageButton
            }
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 36, trailing: 16))
    }
    
    private var downloadImageButton: some View {
        Button(action: {
            Task {
                await captureAndSaveScene()
            }
        }) {
            Image(.imageDownload)
        }
        .disabled(isCapturing)
        .frame(width: 48, height: 48)
        .glassEffect(in: .circle)
    }
    
    /// 핀 버튼 - 메인 뭉치 설정/해제
    private var pinButton: some View {
        Group {
            if let bundle = viewModel.selectedBundle {
                if bundle.isMain {
                    Button {
                        //action
                    } label: {
                        Image(.starFill)
                    }
                    .disabled(true)
                    .frame(width: 48, height: 48)
                    .glassEffect(in: .circle)
                } else {
                    // 메인으로 설정되지 않은 경우 버튼으로 표시
                    Button(action: {
                        showChangeMainBundleAlert = true
                    }) {
                        Image(.star)
                    }
                    .frame(width: 48, height: 48)
                    .glassEffect(in: .circle)
                }
            }
        }
    }
    
    private var changeMainBundleAlert: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image("bangMark")
                    .padding(.vertical, 4)
                
                Text("대표 뭉치를 변경할까요?")
                    .typography(.suit20B)
                    .foregroundStyle(.black100)
                Text("선택한 뭉치가 홈에 걸려요.")
                    .typography(.suit15R)
                    .foregroundStyle(.black100)
            }
            .padding(8)
            
            // 버튼 영역
            HStack(spacing: 16) {
                Button {
                    showChangeMainBundleAlert = false
                } label: {
                    Text("취소")
                        .typography(.suit17SB)
                        .foregroundStyle(.black100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13.5)
                }
                .buttonStyle(.glassProminent)
                .tint(.black10)
                
                Button {
                    viewModel.updateBundleMainStatus(bundle: viewModel.selectedBundle!, isMain: true) { _ in }
                    showChangeMainBundleAlert = false
                } label: {
                    Text("확인")
                        .typography(.suit17SB)
                        .foregroundStyle(.white100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13.5)
                }
                .buttonStyle(.glassProminent)
                .tint(.main500)
            }
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 34))
        .frame(minWidth: 200)
    }
}

//MARK: 캡쳐 오버레이
extension BundleDetailView {
    private var capturingOverlay: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .blur(radius: 15)
            
            Image(.imageSaved)
        }
    }
}
