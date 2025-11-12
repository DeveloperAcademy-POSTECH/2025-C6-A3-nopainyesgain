//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import NukeUI
import FirebaseFirestore

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    @State var collectionViewModel: CollectionViewModel
    @Namespace private var unionNamespace

    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []
    @State private var isLoadingKeyrings = false

    var body: some View {
        ZStack(alignment: .top) {
            contentView
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // 홈 진입 시 main bundle 로드 및 설정
            await loadMainBundle()
        }
    }
    
    // MARK: - Main Bundle Loading
    @MainActor
    private func loadMainBundle() async {
        let startTime = Date()
        print("🏠 [HomeView] loadMainBundle 시작")

        let uid = UserManager.shared.userUID
        guard !uid.isEmpty else { return }

        // 1. 먼저 배경 및 카라비너 데이터 로드 (WorkshopDataManager)
        await collectionViewModel.loadBackgroundsAndCarabiners()
        print("  ✓ [HomeView] 배경/카라비너 데이터 로드 완료")

        // 2. 번들 목록 로드
        await withCheckedContinuation { continuation in
            collectionViewModel.fetchAllBundles(uid: uid) { success in
                continuation.resume()
            }
        }

        // 3. main bundle을 selectedBundle로 설정
        if let mainBundle = collectionViewModel.sortedBundles.first(where: { $0.isMain }) {
            collectionViewModel.selectedBundle = mainBundle
        } else if let firstBundle = collectionViewModel.sortedBundles.first {
            // main bundle이 없으면 첫 번째 bundle 선택
            collectionViewModel.selectedBundle = firstBundle
        } else {
            print("[HomeView] No bundle found")
            return
        }

        // 4. selectedBackground와 selectedCarabiner 설정
        if let bundle = collectionViewModel.selectedBundle {
            collectionViewModel.selectedBackground = collectionViewModel.resolveBackground(from: bundle.selectedBackground)
            collectionViewModel.selectedCarabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner)
            print("  ✓ [HomeView] selectedBackground: \(collectionViewModel.selectedBackground?.id ?? "nil")")
            print("  ✓ [HomeView] selectedCarabiner: \(collectionViewModel.selectedCarabiner?.id ?? "nil")")
        }

        // 5. 키링 데이터 로드
        if let bundle = collectionViewModel.selectedBundle,
           let carabiner = collectionViewModel.selectedCarabiner {
            keyringDataList = await createKeyringDataListFromBundle(bundle: bundle, carabiner: carabiner)
        }

        // 6. 선택된 번들의 이미지 프리페칭
        await prefetchBundleImages()

        let elapsed = Date().timeIntervalSince(startTime)
        print("🏠 [HomeView] loadMainBundle 완료 - 총 소요시간: \(String(format: "%.3f", elapsed))초")
    }

    // MARK: - Image Prefetching
    @MainActor
    private func prefetchBundleImages() async {
        let prefetchStart = Date()
        print("  📦 [HomeView] 이미지 프리페칭 시작...")

        guard let bundle = collectionViewModel.selectedBundle,
              let carabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner),
              let background = collectionViewModel.selectedBackground else {
            print("  ⚠️ [HomeView] 프리페칭할 데이터 없음")
            return
        }

        // 프리페치할 이미지 경로 수집
        var imagePaths: [String] = []

        // 1. 배경 이미지
        imagePaths.append(background.backgroundImage)

        // 2. 카라비너 이미지
        let carabinerType = CarabinerType.from(carabiner.carabinerType)
        if carabinerType == .hamburger {
            if carabiner.carabinerImage.count > 1 {
                imagePaths.append(carabiner.carabinerImage[1]) // back
            }
            if carabiner.carabinerImage.count > 2 {
                imagePaths.append(carabiner.carabinerImage[2]) // front
            }
        } else {
            if !carabiner.carabinerImage.isEmpty {
                imagePaths.append(carabiner.carabinerImage[0]) // plain
            }
        }

        // 3. 키링 body 이미지들
        for keyringId in bundle.keyrings {
            guard keyringId != "none" else { continue }

            // Firestore에서 키링 정보 가져오기
            if let keyring = await fetchKeyringInfo(keyringId: keyringId) {
                imagePaths.append(keyring.bodyImage)
            }
        }

        print("  📥 [HomeView] \(imagePaths.count)개 이미지 다운로드 시작...")

        // 병렬로 모든 이미지 다운로드
        do {
            let _ = try await StorageManager.shared.getMultipleImages(paths: imagePaths)
            let elapsed = Date().timeIntervalSince(prefetchStart)
            print("  ✅ [HomeView] 이미지 프리페칭 완료 - 소요시간: \(String(format: "%.3f", elapsed))초")
        } catch {
            print("  ❌ [HomeView] 이미지 프리페칭 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch Keyring Info (for prefetching)
    private func fetchKeyringInfo(keyringId: String) async -> SimpleKeyringInfo? {
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let document = try await db.collection("Keyring").document(keyringId).getDocument()

            guard let data = document.data(),
                  let bodyImage = data["bodyImage"] as? String else {
                return nil
            }

            return SimpleKeyringInfo(id: keyringId, bodyImage: bodyImage)
        } catch {
            print("  ⚠️ [HomeView] 키링 정보 로드 실패: \(keyringId)")
            return nil
        }
    }

    private struct SimpleKeyringInfo {
        let id: String
        let bodyImage: String
    }

    private struct KeyringInfo {
        let id: String
        let bodyImage: String
        let soundId: String
        let particleId: String
    }

    // MARK: - Create Keyring Data List
    private func createKeyringDataListFromBundle(bundle: KeyringBundle, carabiner: Carabiner) async -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        print("🔍 [HomeView] createKeyringDataList 시작 - bundle.keyrings: \(bundle.keyrings)")

        // bundle.keyrings 배열을 순회 (각 요소는 Firestore 문서 ID)
        for (index, keyringId) in bundle.keyrings.enumerated() {
            guard index < carabiner.maxKeyringCount else { break }
            guard keyringId != "none", !keyringId.isEmpty else {
                print("  [Index \(index)] 키링 없음 (none)")
                continue
            }

            // Firestore에서 키링 상세 정보 가져오기
            guard let keyringInfo = await fetchFullKeyringInfo(keyringId: keyringId) else {
                print("  ❌ [Index \(index)] 키링 정보 로드 실패: \(keyringId)")
                continue
            }

            print("  ✅ [Index \(index)] 키링 로드 성공: \(keyringId)")

            // 커스텀 사운드 URL 처리
            let customSoundURL: URL? = {
                if keyringInfo.soundId.hasPrefix("https://") || keyringInfo.soundId.hasPrefix("http://") {
                    return URL(string: keyringInfo.soundId)
                }
                return nil
            }()

            // 비율 좌표 가져오기
            let relativePosition = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )

            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: relativePosition,
                bodyImageURL: keyringInfo.bodyImage,
                soundId: keyringInfo.soundId,
                customSoundURL: customSoundURL,
                particleId: keyringInfo.particleId
            )
            dataList.append(data)
        }

        print("🔍 [HomeView] createKeyringDataList 완료 - 키링 개수: \(dataList.count)")
        return dataList
    }

    // MARK: - Fetch Full Keyring Info (including sound and particle)
    private func fetchFullKeyringInfo(keyringId: String) async -> KeyringInfo? {
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let document = try await db.collection("Keyring").document(keyringId).getDocument()

            guard let data = document.data(),
                  let bodyImage = data["bodyImage"] as? String,
                  let soundId = data["soundId"] as? String,
                  let particleId = data["particleId"] as? String else {
                return nil
            }

            return KeyringInfo(
                id: keyringId,
                bodyImage: bodyImage,
                soundId: soundId,
                particleId: particleId
            )
        } catch {
            print("  ⚠️ [HomeView] 키링 정보 로드 실패: \(keyringId) - \(error.localizedDescription)")
            return nil
        }
    }
}

//MARK: - 씬 뷰 컴포넌트
extension HomeView {
    private var contentView: some View {
        print("🎨 [HomeView] contentView 렌더링 - selectedBundle: \(collectionViewModel.selectedBundle?.documentId ?? "nil")")

        return Group {
            if let bundle = collectionViewModel.selectedBundle {
                bundleSceneView(bundle: bundle)
            } else {
                ProgressView("번들 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .id(collectionViewModel.selectedBundle?.documentId ?? "no-bundle")
    }

    /// 번들 씬 뷰
    private func bundleSceneView(bundle: KeyringBundle) -> some View {
        VStack {
            if let carabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner) {
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
        let _ = print("🎨 [HomeView] sceneLayerView 렌더링 - selectedBackground: \(collectionViewModel.selectedBackground?.id ?? "nil"), keyringDataList count: \(keyringDataList.count)")

        return VStack {
            if let background = collectionViewModel.selectedBackground {
                let _ = print("🎨 [HomeView] MultiKeyringSceneView 생성 - 키링 개수: \(keyringDataList.count)")

                MultiKeyringSceneView(
                    keyringDataList: keyringDataList,
                    ringType: .basic,
                    chainType: .basic,
                    backgroundColor: .clear,
                    backgroundImageURL: background.backgroundImage,
                    carabinerBackImageURL: carabiner.backImageURL,
                    carabinerFrontImageURL: carabiner.frontImageURL,
                    currentCarabinerType: carabiner.type
                )
                .id("\(background.id)_\(carabiner.id)_\(keyringDataList.map { $0.index }.sorted())")
            } else {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Spacer()
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .id(collectionViewModel.selectedBackground?.id ?? "loading")
    }
}
