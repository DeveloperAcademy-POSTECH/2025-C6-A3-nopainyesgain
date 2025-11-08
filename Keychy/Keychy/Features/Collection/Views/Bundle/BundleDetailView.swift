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
                // 배경 이미지
                backgroundImage
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if let bundle = viewModel.selectedBundle {
                    VStack {
                        ZStack(alignment: .top) {
                            // 1층: 뒷 카라비너 이미지 표시
                            Group {
                                if let carabiner = resolveCarabiner(from: bundle.selectedCarabiner) {
                                    LazyImage(url: URL(string: carabiner.carabinerImage[safe: 1] ?? "")) { state in
                                        if let image = state.image {
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        } else if state.isLoading {
                                            ProgressView()
                                        } else if state.error != nil {
                                            Color.clear
                                        } else {
                                            Color.clear
                                        }
                                    }
                                } else {
                                    Color.clear
                                }
                            }
                            
                            // 2층: 여러 키링을 하나의 씬에 표시
                            Group {
                                if let carabiner = resolveCarabiner(from: bundle.selectedCarabiner), 
                                   didPrefetch, isSceneReady, scenePreparationDelay, allKeyringsStabilized {
                                    let dataList = createKeyringDataList(carabiner: carabiner, geometry: geometry.size)
                                    MultiKeyringSceneView(
                                        keyringDataList: dataList,
                                        ringType: .basic,
                                        chainType: .basic,
                                        backgroundColor: .clear
                                    )
                                    // BundleAddKeyringView와 동일한 방식으로 id 설정
                                    .id(dataList.map { $0.index }.sorted())
                                    .opacity(allKeyringsStabilized ? 1.0 : 0.0)
                                    .animation(.easeInOut(duration: 0.5), value: allKeyringsStabilized)
                                } else {
                                    Color.clear
                                }
                            }
                            
                            // 3층 : 앞 카라비너 이미지 표시 (햄버거 구조)
                            Group {
                                if let carabiner = resolveCarabiner(from: bundle.selectedCarabiner) {
                                    LazyImage(url: URL(string: carabiner.carabinerImage[safe: 2] ?? "")) { state in
                                        if let image = state.image {
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        } else if state.isLoading {
                                            ProgressView()
                                        } else if state.error != nil {
                                            Color.clear
                                        } else {
                                            Color.clear
                                        }
                                    }
                                } else {
                                    Color.clear
                                }
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.gray400)
                        Text("선택된 뭉치가 없어요")
                            .typography(.suit16M)
                            .foregroundStyle(.gray500)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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

            // BundleAddKeyringView와 동일한 씬 준비 과정 추가
            if let bundle = viewModel.selectedBundle,
               let carabiner = resolveCarabiner(from: bundle.selectedCarabiner),
               let backImageURL = carabiner.carabinerImage[safe: 1] {
                
                // 카라비너 이미지와 키링 바디 이미지들을 모두 프리로드
                Task {
                    do {
                        // 1. 카라비너 이미지 로드
                        let _ = try await StorageManager.shared.getImage(path: backImageURL)
                        print("[BundleDetailView] Carabiner image loaded")
                        
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

    // MARK: - Resolve Helpers (id -> Model)
    private func resolveCarabiner(from id: String) -> Carabiner? {
        viewModel.carabiners.first { $0.id == id }
    }

    private func resolveBackground(from id: String) -> Background? {
        viewModel.backgrounds.first { $0.id == id }
    }
    
    /// Firestore 문서 id -> Keyring 모델 해석
    private func resolveKeyring(from documentId: String) -> Keyring? {
        // 사용자 보유 키링 배열에서 로컬 UUID -> 문서 id 매핑을 이용해 역으로 찾기
        let result = viewModel.keyring.first { kr in
            viewModel.keyringDocumentIdByLocalId[kr.id] == documentId
        }
        print("[BundleDetailView] resolveKeyring for docId=\(documentId): \(result?.name ?? "nil")")
        print("[BundleDetailView] keyringDocumentIdByLocalId keys: \(viewModel.keyringDocumentIdByLocalId.keys.count)")
        return result
    }
}

extension BundleDetailView {
    /// 번들에 저장된 문서 id 배열을 기반으로 MultiKeyringScene.KeyringData 배열 생성
    fileprivate func createKeyringDataList(
        carabiner: Carabiner,
        geometry: CGSize
    ) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        guard let bundle = viewModel.selectedBundle else {
            return dataList
        }

        // bundle.keyrings 배열을 순회 (각 인덱스는 카라비너 위치)
        for index in 0..<carabiner.maxKeyringCount {
            // 번들에 저장된 문서 id (없으면 "none")
            let docId = bundle.keyrings[safe: index] ?? "none"
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

extension BundleDetailView {
    /// 배경 이미지 뷰 (Bundle에 저장된 background id를 실제 모델로 해석)
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
    }
}

#Preview {
    BundleDetailView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
