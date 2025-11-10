//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import NukeUI

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    @State var collectionViewModel: CollectionViewModel
    @Namespace private var unionNamespace
    
    //MARK: - 씬 상태 관리 프로퍼티
    @State private var didPrefetch: Bool = false
    @State private var isLoading: Bool = false
    @State private var isSceneReady: Bool = false
    @State private var scenePreparationDelay: Bool = false  // 씬 준비를 위한 추가 지연
    @State private var physicsEnabled: Bool = false  // 물리 시뮬레이션 활성화 상태
    @State private var allKeyringsStabilized: Bool = false  // 모든 키링 안정화 완료
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                contentView(geometry: geo)
                HStack(spacing: 10) {
                    Spacer()
                    
                    Button {
                        router.push(.bundleInventoryView)
                    } label: {
                        Image(.bundleIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glassProminent)
                    
                    GlassEffectContainer {
                        HStack(spacing: 0) {
                            Button {
                                router.push(.alarmView)
                            } label: {
                                Image(.alarmIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.glassProminent)
                            .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                            
                            Button {
                                router.push(.myPageView)
                            } label: {
                                Image(.myPageIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                            }
                            
                            .buttonStyle(.glassProminent)
                            .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .tint(.white.opacity(0.8))
            }
        }
        .background(collectionViewModel.backgroundImage)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // 홈 진입 시 main bundle 로드 및 설정
            await loadMainBundle()
        }
        .task {
            // 첫 진입 시 한 번만 프리패치
            guard !didPrefetch else { return }
            isLoading = true
            
            // 1) 배경/카라비너 프리패치
            await collectionViewModel.loadBackgroundsAndCarabiners()
            
            // 2) 사용자 키링 보장 로드 (이미 있으면 스킵)
            if collectionViewModel.keyring.isEmpty {
                let uid = UserManager.shared.userUID
                if !uid.isEmpty {
                    await withCheckedContinuation { continuation in
                        collectionViewModel.fetchUserKeyrings(uid: uid) { _ in
                            continuation.resume()
                        }
                    }
                }
            }
            
            isLoading = false
            didPrefetch = true
            if let bundle = collectionViewModel.selectedBundle, let carabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner) {
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
                        let dataList = collectionViewModel.createKeyringDataList(carabiner: carabiner, geometry: CGSize(width: 400, height: 800))
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
    
    // MARK: - Main Bundle Loading
    @MainActor
    private func loadMainBundle() async {
        let uid = UserManager.shared.userUID
        guard !uid.isEmpty else { return }
        
        // 번들 목록 로드
        await withCheckedContinuation { continuation in
            collectionViewModel.fetchAllBundles(uid: uid) { success in
                continuation.resume()
            }
        }
        
        // main bundle을 selectedBundle로 설정
        if let mainBundle = collectionViewModel.sortedBundles.first(where: { $0.isMain }) {
            collectionViewModel.selectedBundle = mainBundle
        } else if let firstBundle = collectionViewModel.sortedBundles.first {
            // main bundle이 없으면 첫 번째 bundle 선택
            collectionViewModel.selectedBundle = firstBundle
        } else {
            print("[HomeView] No bundle found")
        }
    }
}

//MARK: - 씬 뷰 컴포넌트
extension HomeView {
    private func contentView(geometry: GeometryProxy) -> some View {
        Group {
            if let bundle = collectionViewModel.selectedBundle {
                bundleSceneView(bundle: bundle, geometry: geometry)
            }
        }
        .ignoresSafeArea()
    }
    
    /// 번들 씬 뷰
    private func bundleSceneView(bundle: KeyringBundle, geometry: GeometryProxy) -> some View {
        VStack {
            if let carabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner) {
                sceneLayerView(carabiner: carabiner, geometry: geometry)
            } else {
                Color.clear
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    /// 씬 레이어 뷰 (카라비너와 키링들)
    private func sceneLayerView(carabiner: Carabiner, geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            switch carabiner.type {
            case .hamburger:
                // 1층: 뒷 카라비너 이미지
                collectionViewModel.backCarabinerImage(carabiner: carabiner)
                
                // 2층: 키링 씬 (BundleAddKeyringView와 동일하게 직접 배치)
                Group {
                    if didPrefetch && isSceneReady && scenePreparationDelay && allKeyringsStabilized {
                        let dataList = collectionViewModel.createKeyringDataList(carabiner: carabiner, geometry: geometry.size)
                        MultiKeyringSceneView(
                            keyringDataList: dataList,
                            ringType: .basic,
                            chainType: .basic,
                            backgroundColor: .clear,
                            currentCarabinerType: carabiner.type
                        )
                        .id(dataList.map { $0.index }.sorted())
                        .opacity(allKeyringsStabilized ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: allKeyringsStabilized)
                    } else {
                        Color.clear
                    }
                }
                
                // 3층: 앞 카라비너 이미지
                collectionViewModel.frontCarabinerImage(carabiner: carabiner)
                
            case .plain:
                // 1층: 카라비너 이미지
                collectionViewModel.backCarabinerImage(carabiner: carabiner)
                
                // 2층: 키링 씬 (BundleAddKeyringView와 동일하게 직접 배치)
                Group {
                    if didPrefetch && isSceneReady && scenePreparationDelay && allKeyringsStabilized {
                        let dataList = collectionViewModel.createKeyringDataList(carabiner: carabiner, geometry: geometry.size)
                        MultiKeyringSceneView(
                            keyringDataList: dataList,
                            currentCarabinerType: carabiner.type
                        )
                        .id(dataList.map { $0.index }.sorted())
                        .opacity(allKeyringsStabilized ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: allKeyringsStabilized)
                    } else {
                        Color.clear
                    }
                }
            }
        }
        .padding(.top, 60)
    }
}
