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
            } else {
                // 데이터 로딩 중
                Color.clear.ignoresSafeArea()
            }
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
                            }
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
            // 삭제 확인 Alert
            if showDeleteAlert {
                deleteAlertView
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
            let db = Firestore.firestore()
            
            // Firebase에서 문서 삭제
            try await db.collection("KeyringBundle").document(documentId).delete()
            
            // 로컬 배열에서도 제거
            viewModel.bundles.removeAll { $0.documentId == documentId }
            
            // Alert 닫기
            showDeleteAlert = false
            
            // 이전 화면으로 이동
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
    /// 삭제 확인 Alert
    private var deleteAlertView: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDeleteAlert = false
                    }
                }
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // 타이틀
                    Text("뭉치를 삭제하시겠어요?")
                        .typography(.suit17B)
                        .foregroundStyle(.black100)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                    
                    // 메시지
                    Text("삭제된 뭉치는 복구할 수 없어요")
                        .typography(.suit15R)
                        .foregroundStyle(.gray600)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                    
                    Divider()
                    
                    // 버튼들
                    HStack(spacing: 0) {
                        // 취소 버튼
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDeleteAlert = false
                            }
                        } label: {
                            Text("취소")
                                .typography(.suit16M)
                                .foregroundStyle(.black100)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        
                        Divider()
                        
                        // 삭제 버튼
                        Button {
                            Task {
                                await deleteBundle()
                            }
                        } label: {
                            Text("삭제")
                                .typography(.suit16M)
                                .foregroundStyle(.primaryRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                }
                .background(.white100)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 51)
                
                Spacer()
            }
        }
    }
    
    /// 메뉴 오버레이
    private var menuOverlay: some View {
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
                    },
                    onDelete: {
                        showMenu = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteAlert = true
                        }
                    }
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
    
    /// 하단 정보 섹션 - 핀 버튼, 뭉치 이름/개수, 다운로드 버튼
    private var bottomSection: some View {
        VStack {
            Spacer()
            HStack {
                pinButton
                Spacer()
                Text("\(viewModel.selectedBundle!.name)\n\(viewModel.selectedBundle!.keyrings.count) / \(viewModel.selectedBundle!.maxKeyrings)")
                    .foregroundStyle(.gray600)
                    .typography(.notosans15M)
                Spacer()
                downloadImageButton
            }
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 36, trailing: 16))
    }
    
    private var downloadImageButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMenu.toggle()
            }
        }) {
            Image(.imageDownload)
                .foregroundStyle(.gray600)
        }
        .buttonStyle(.glassProminent)
    }
    
    /// 핀 버튼 - 메인 뭉치 설정/해제
    private var pinButton: some View {
        Group {
            if viewModel.selectedBundle!.isMain {
                // 이미 메인으로 설정된 경우 채워진 핀 아이콘만 표시
                Image(.pinButtonFill)
            } else {
                // 메인으로 설정되지 않은 경우 버튼으로 표시
                Button(action: {
                    viewModel.updateBundleMainStatus(bundle: viewModel.selectedBundle!, isMain: true) { _ in }
                }) {
                    Image(.pinButton)
                        .foregroundStyle(.gray600)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }
}
