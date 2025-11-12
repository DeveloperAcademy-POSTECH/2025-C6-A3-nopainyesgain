//
//  BundleDetailView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//
// 키링 뭉치 상세보기 화면
import SwiftUI
import NukeUI
import FirebaseFirestore

struct BundleDetailView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel

    // MARK: - 상태 관리
    @State private var showMenu: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []

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
            await prefetchBundleImages()
        }
    }
}

// MARK: - Image Prefetching
extension BundleDetailView {
    @MainActor
    private func prefetchBundleImages() async {
        let prefetchStart = Date()
        print("📸 [BundleDetailView] 이미지 프리페칭 시작...")

        // 1. 배경 및 카라비너 데이터 로드 (필요한 경우)
        await viewModel.loadBackgroundsAndCarabiners()

        // 2. selectedBackground와 selectedCarabiner 설정
        guard let bundle = viewModel.selectedBundle else {
            print("  ⚠️ [BundleDetailView] selectedBundle 없음")
            return
        }

        viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
        viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)

        guard let carabiner = viewModel.selectedCarabiner,
              let background = viewModel.selectedBackground else {
            print("  ⚠️ [BundleDetailView] 프리페칭할 데이터 없음")
            print("    - background: \(viewModel.selectedBackground?.id ?? "nil")")
            print("    - carabiner: \(viewModel.selectedCarabiner?.id ?? "nil")")
            return
        }

        print("  ✓ [BundleDetailView] selectedBackground: \(background.id)")
        print("  ✓ [BundleDetailView] selectedCarabiner: \(carabiner.id)")

        // 키링 데이터 로드
        keyringDataList = await createKeyringDataListFromBundle(bundle: bundle, carabiner: carabiner)

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

        print("  📥 [BundleDetailView] \(imagePaths.count)개 이미지 다운로드 시작...")

        // 병렬로 모든 이미지 다운로드
        do {
            let _ = try await StorageManager.shared.getMultipleImages(paths: imagePaths)
            let elapsed = Date().timeIntervalSince(prefetchStart)
            print("  ✅ [BundleDetailView] 이미지 프리페칭 완료 - 소요시간: \(String(format: "%.3f", elapsed))초")
        } catch {
            print("  ❌ [BundleDetailView] 이미지 프리페칭 실패: \(error.localizedDescription)")
        }
    }

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
            print("  ⚠️ [BundleDetailView] 키링 정보 로드 실패: \(keyringId)")
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

        print("🔍 [BundleDetailView] createKeyringDataList 시작 - bundle.keyrings: \(bundle.keyrings)")

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

        print("🔍 [BundleDetailView] createKeyringDataList 완료 - 키링 개수: \(dataList.count)")
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
            print("  ⚠️ [BundleDetailView] 키링 정보 로드 실패: \(keyringId) - \(error.localizedDescription)")
            return nil
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
        let _ = print("🎨 [BundleDetailView] sceneLayerView 렌더링 - keyringDataList count: \(keyringDataList.count)")

        return VStack {
            if let background = viewModel.selectedBackground {
                let _ = print("🎨 [BundleDetailView] MultiKeyringSceneView 생성 - 키링 개수: \(keyringDataList.count)")

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
        .id(viewModel.selectedBackground?.id ?? "loading")
    }
}
