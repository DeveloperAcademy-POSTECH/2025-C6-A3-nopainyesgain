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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundImage
                contentView(geometry: geometry)
            }
        }
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
            if let bundle = viewModel.selectedBundle, let carabiner = resolveCarabiner(from: bundle.selectedCarabiner) {
                // 카라비너 이미지와 키링 바디 이미지들을 모두 프리로드
                Task {
                    do {
                        // 1. 카라비너 이미지들 로드
                        let _ = try await StorageManager.shared.getImage(path: carabiner.backImageURL)
                        
                        // 햄버거 타입이면 앞면 이미지도 로드
                        if let frontURL = carabiner.frontImageURL {
                            let _ = try await StorageManager.shared.getImage(path: frontURL)
                        }
                        
                        print("[BundleDetailView] Carabiner images loaded")
                        
                        // 2. 모든 키링 바디 이미지들 프리로드
                        let dataList = createKeyringDataList(carabiner: carabiner, geometry: CGSize(width: 400, height: 800))
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
                            print("[BundleDetailView] All images preloaded, scene ready!")
                            
                            // 모든 이미지가 로드된 후 짧은 안정화 시간
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    self.scenePreparationDelay = true
                                }
                                
                                // 키링 씬이 자체적으로 안정화를 관리하므로 짧은 추가 대기만
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        self.allKeyringsStabilized = true
                                        print("[BundleDetailView] Scene ready to display!")
                                    }
                                }
                            }
                        }
                    } catch {
                        print("[BundleDetailView] Failed to preload images: \(error)")
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
                                        print("[BundleDetailView] Scene ready (error case)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 프리패치 후 디버그
            print("[BundleDetailView] Prefetch done. carabiners: \(viewModel.carabiners.count), backgrounds: \(viewModel.backgrounds.count), keyrings: \(viewModel.keyring.count)")
            if let bundle = viewModel.selectedBundle {
                print("[BundleDetailView] selectedCarabiner id: \(bundle.selectedCarabiner)")
                print("[BundleDetailView] selectedBackground id: \(bundle.selectedBackground)")
                print("[BundleDetailView] resolveCarabiner: \(resolveCarabiner(from: bundle.selectedCarabiner) != nil), resolveBackground: \(resolveBackground(from: bundle.selectedBackground) != nil)")
                print("[BundleDetailView] bundle keyring docIds: \(bundle.keyrings)")
            }
        }
    }
}

// MARK: - View Components

extension BundleDetailView {
    /// 메인 컨텐츠 뷰
    private func contentView(geometry: GeometryProxy) -> some View {
        Group {
            if let bundle = viewModel.selectedBundle {
                bundleSceneView(bundle: bundle, geometry: geometry)
            }
        }
        .ignoresSafeArea()
    }
    
    /// 번들 씬 뷰
    private func bundleSceneView(bundle: KeyringBundle, geometry: GeometryProxy) -> some View {
        VStack {
            if let carabiner = resolveCarabiner(from: bundle.selectedCarabiner) {
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
                backCarabinerImage(carabiner: carabiner)
                
                // 2층: 키링 씬 (BundleAddKeyringView와 동일하게 직접 배치)
                Group {
                    if didPrefetch && isSceneReady && scenePreparationDelay && allKeyringsStabilized {
                        let dataList = createKeyringDataList(carabiner: carabiner, geometry: geometry.size)
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
                frontCarabinerImage(carabiner: carabiner)
                
            case .plain:
                // 1층: 카라비너 이미지
                backCarabinerImage(carabiner: carabiner)
                
                // 2층: 키링 씬 (BundleAddKeyringView와 동일하게 직접 배치)
                Group {
                    if didPrefetch && isSceneReady && scenePreparationDelay && allKeyringsStabilized {
                        let dataList = createKeyringDataList(carabiner: carabiner, geometry: geometry.size)
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
    
    /// 뒷 카라비너 이미지 (또는 단일 카라비너 이미지)
    private func backCarabinerImage(carabiner: Carabiner) -> some View {
        LazyImage(url: URL(string: carabiner.backImageURL)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if state.isLoading {
                ProgressView()
            } else {
                Color.clear
            }
        }
    }
    
    /// 앞 카라비너 이미지 (햄버거 타입만)
    private func frontCarabinerImage(carabiner: Carabiner) -> some View {
        Group {
            if let frontURL = carabiner.frontImageURL {
                LazyImage(url: URL(string: frontURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.isLoading {
                        ProgressView()
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
    }
    
    /// 배경 이미지 뷰
    private var backgroundImage: some View {
        Group {
            if let bundle = viewModel.selectedBundle,
               let bg = resolveBackground(from: bundle.selectedBackground) {
                LazyImage(url: URL(string: bg.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if state.isLoading {
                        Color.clear
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Data Management

extension BundleDetailView {
    /// Resolve Helpers (id -> Model)
    private func resolveCarabiner(from id: String) -> Carabiner? {
        viewModel.carabiners.first { $0.id == id }
    }
    
    private func resolveBackground(from id: String) -> Background? {
        viewModel.backgrounds.first { $0.id == id }
    }
    
    /// Firestore 문서 id -> Keyring 모델 해석
    private func resolveKeyring(from documentId: String) -> Keyring? {
        let result = viewModel.keyring.first { kr in
            viewModel.keyringDocumentIdByLocalId[kr.id] == documentId
        }
        print("[BundleDetailView] resolveKeyring for docId=\(documentId): \(result?.name ?? "nil")")
        print("[BundleDetailView] keyringDocumentIdByLocalId keys: \(viewModel.keyringDocumentIdByLocalId.keys.count)")
        return result
    }
}

// MARK: - Helper Methods

extension BundleDetailView {
    /// 번들에 저장된 문서 id 배열을 기반으로 MultiKeyringScene.KeyringData 배열 생성
    private func createKeyringDataList(carabiner: Carabiner, geometry: CGSize) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []
        
        guard let bundle = viewModel.selectedBundle else {
            return dataList
        }
        
        // bundle.keyrings 배열을 순회 (각 인덱스는 카라비너 위치)
        for index in 0..<carabiner.maxKeyringCount {
            // 번들에 저장된 문서 id (없으면 "none")
            let docId = bundle.keyrings[index] ?? "none"
            if docId == "none" || docId.isEmpty {
                print("[BundleDetailView] dataList skip carabinerPos=\(index) (no keyring)")
                continue
            }
            
            guard let keyring = resolveKeyring(from: docId) else {
                print("[BundleDetailView] dataList skip carabinerPos=\(index) (keyring not found for docId=\(docId))")
                continue
            }
            
            print("[BundleDetailView] dataList add carabinerPos=\(index)")
            print("[BundleDetailView] keyring: name=\(keyring.name), body=\(keyring.bodyImage)")
            print("[BundleDetailView] sound=\(keyring.soundId), particle=\(keyring.particleId)")
            print("[BundleDetailView] position: x=\(carabiner.keyringXPosition[index]), y=\(carabiner.keyringYPosition[index])")
            
            let soundId = keyring.soundId
            
            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()
            
            let relativePosition = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )
            
            let data = MultiKeyringScene.KeyringData(
                index: index, // 카라비너 위치 인덱스
                position: relativePosition,
                bodyImageURL: keyring.bodyImage,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: keyring.particleId
            )
            dataList.append(data)
        }
        print("[BundleDetailView] dataList count = \(dataList.count)")
        
        return dataList
    }
}

#Preview {
    BundleDetailView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
