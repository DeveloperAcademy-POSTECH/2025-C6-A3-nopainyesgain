//
//  BundleDetailView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//
// 키링 뭉치 상세보기 화면
import SwiftUI
import NukeUI

struct BundleDetailView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    // MARK: - 상태 관리
    @State private var didPrefetch: Bool = false
    @State private var isLoading: Bool = false
    @State private var isSceneReady: Bool = false
    @State private var scenePreparationDelay: Bool = false  // 씬 준비를 위한 추가 지연
    @State private var physicsEnabled: Bool = false  // 물리 시뮬레이션 활성화 상태
    @State private var allKeyringsStabilized: Bool = false  // 모든 키링 안정화 완료
    @State private var showMenu: Bool = false
    @State private var showDeleteAlert: Bool = false
    
    var body: some View {
        ZStack {
            contentView

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
            // 첫 진입 시 한 번만 프리패치
            guard !didPrefetch else { return }
            isLoading = true
            
            // 1) 배경/카라비너 프리패치
            await viewModel.loadBackgroundsAndCarabiners()
            
            // 2) 사용자 키링 보장 로드 (이미 있으면 스킵)
            if viewModel.keyring.isEmpty {
                let uid = UserManager.shared.userUID
                if !uid.isEmpty {
                    await withCheckedContinuation { continuation in
                        viewModel.fetchUserKeyrings(uid: uid) { _ in
                            continuation.resume()
                        }
                    }
                }
            }
            
            isLoading = false
            didPrefetch = true
            if let bundle = viewModel.selectedBundle, let carabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner) {
                // 카라비너 이미지와 키링 바디 이미지들을 모두 프리로드
                Task {
                    do {
                        // 1. 카라비너 이미지들 로드
                        let _ = try await StorageManager.shared.getImage(path: carabiner.backImageURL)
                        
                        // 햄버거 타입이면 앞면 이미지도 로드
                        if let frontURL = carabiner.frontImageURL {
                            let _ = try await StorageManager.shared.getImage(path: frontURL)
                        }
                        
                        // 2. 모든 키링 바디 이미지들 프리로드
                        let dataList = viewModel.createKeyringDataList(carabiner: carabiner, geometry: CGSize(width: 400, height: 800))
                        for keyringData in dataList {
                            if !keyringData.bodyImageURL.isEmpty {
                                do {
                                    let _ = try await StorageManager.shared.getImage(path: keyringData.bodyImageURL)
                                    print("[BundleDetailView] Preloaded keyring image: \(keyringData.index)")
                                } catch {
                                    print("[BundleDetailView] Failed to preload keyring \(keyringData.index): \(error)")
                                }
                            }
                        }
                        
                        await MainActor.run {
                            self.isSceneReady = true
                            
                            // 모든 이미지가 로드된 후 짧은 안정화 시간
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    self.scenePreparationDelay = true
                                }
                                
                                // 키링 씬이 자체적으로 안정화를 관리하므로 짧은 추가 대기만
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        self.allKeyringsStabilized = true
                                    }
                                }
                            }
                        }
                    } catch {
                        await MainActor.run {
                            self.isSceneReady = true
                            
                            // 실패 시 더 긴 대기 시간
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    self.scenePreparationDelay = true
                                }
                                
                                // 실패 케이스에서도 간단한 대기
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        self.allKeyringsStabilized = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 툴바
extension BundleDetailView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.gray600)
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

//MARK: - 하단 섹션
extension BundleDetailView {
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
    
    private var pinButton: some View {
        // 메인 설정이 되어있을 때는 이미지만 선택합니다.
        Group {
            if viewModel.selectedBundle!.isMain {
                Image(.pinButtonFill)
            } else {
                Button(action: {
                    viewModel.updateBundleMainStatus(bundle: viewModel.selectedBundle!, isMain: true) { success in
                        if success {
                            print("메인 번들 설정 완료")
                        } else {
                            print("메인 번들 설정 실패")
                        }
                    }
                }) {
                    Image(.pinButton)
                        .foregroundStyle(.gray600)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }
}

// MARK: - View Components
extension BundleDetailView {
    /// 메인 컨텐츠 뷰
    private var contentView: some View {
        Group {
            if let bundle = viewModel.selectedBundle {
                bundleSceneView(bundle: bundle)
            }
        }
        .ignoresSafeArea()
    }

    /// 번들 씬 뷰
    private func bundleSceneView(bundle: KeyringBundle) -> some View {
        VStack {
            if let carabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner) {
                sceneLayerView(carabiner: carabiner)
            } else {
                Color.clear
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 씬 레이어 뷰 (카라비너와 키링들)
    private func sceneLayerView(carabiner: Carabiner) -> some View {
        VStack {
            Group {
                if didPrefetch && isSceneReady && scenePreparationDelay && allKeyringsStabilized,
                   let background = viewModel.selectedBackground {
                    let dataList = viewModel.createKeyringDataList(carabiner: carabiner, geometry: CGSize(width: 393, height: 852))

                    switch carabiner.type {
                    case .hamburger:
                        MultiKeyringSceneView(
                            keyringDataList: dataList,
                            ringType: .basic,
                            chainType: .basic,
                            backgroundColor: .clear,
                            backgroundImageURL: background.backgroundImage,
                            carabinerBackImageURL: carabiner.backImageURL,
                            carabinerFrontImageURL: carabiner.frontImageURL,
                            currentCarabinerType: carabiner.type
                        )
                        .id(dataList.map { $0.index }.sorted())
                        .opacity(allKeyringsStabilized ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: allKeyringsStabilized)

                    case .plain:
                        MultiKeyringSceneView(
                            keyringDataList: dataList,
                            ringType: .basic,
                            chainType: .basic,
                            backgroundColor: .clear,
                            backgroundImageURL: background.backgroundImage,
                            carabinerBackImageURL: carabiner.backImageURL,
                            carabinerFrontImageURL: nil,
                            currentCarabinerType: carabiner.type
                        )
                        .id(dataList.map { $0.index }.sorted())
                        .opacity(allKeyringsStabilized ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: allKeyringsStabilized)
                    }
                } else {
                    Color.clear
                }
            }
            Spacer()
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
