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

struct BundleDetailView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    // MARK: - State Management
    @State private var showMenu: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteCompleteToast: Bool = false
    @State private var showChangeMainBundleAlert: Bool = false
    @State var isCapturing: Bool = false
    
    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []
    
    // MARK: - Body
    var body: some View {
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
                    currentCarabinerType: carabiner.type
                )
                .ignoresSafeArea()
                /// 씬 재생성 조건을 위한 ID 설정
                /// 배경, 카라비너, 키링 구성이 변경되면 씬을 완전히 재생성
                .id("\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map(\.index).sorted())")
                
                // 하단 섹션을 ZStack 안에서 직접 배치
                VStack {
                    Spacer()
                    bottomSection
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                
                if showMenu {
                    HStack {
                        Spacer()
                        VStack {
                            BundleMenu(
                                onNameEdit: {
                                    showMenu = false
                                    router.push(.bundleNameEditView)
                                },
                                onEdit: {
                                    showMenu = false
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
                    .zIndex(50)
                    .allowsHitTesting(true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
                }
            } else {
                // 데이터 로딩 중
                Color.clear.ignoresSafeArea()
            }
            
            if isCapturing {
                capturingOverlay
            }
        }
        .toolbar {
            backToolbarItem
            menuToolbarItem
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .task {
            // 뷰가 나타날 때 뭉치 데이터 로드
            await loadBundleData()
        }
        .overlay {
            ZStack(alignment: .center) {
                // 삭제 확인 Alert
                if showDeleteAlert {
                    Color.black.opacity(0.4)
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
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    DeleteCompletePopup(isPresented: $showDeleteCompleteToast)
                        .zIndex(100)
                }
                
                if showChangeMainBundleAlert {
                    Color.black.opacity(0.4)
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

// MARK: - Toolbar
extension BundleDetailView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.gray600)
            }
        }
    }
    
    private var menuToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }) {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.gray600)
            }
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
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("이미지 생성 중...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
}
