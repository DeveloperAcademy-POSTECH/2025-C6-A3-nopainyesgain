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
            // 메인 씬 뷰
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
                    currentCarabinerType: carabiner.type
                )
                .ignoresSafeArea()

                /// 이 코드는 다음 조건이 하나라도 변경되면 MultiKeyringSceneView를 완전히 재생성합니다:
                /// - background.id 변경 (배경 이미지 변경)
                /// - carabiner.id 변경 (카라비너 변경)
                /// - keyringDataList의 인덱스 구성 변경 (키링 추가/삭제/순서 변경)
                .id("\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map(\.index).sorted())")
            } else {
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
            await loadBundleData()
        }
    }
}

// MARK: - Data Loading
extension BundleDetailView {
    @MainActor
    private func loadBundleData() async {
        // 배경 및 카라비너 데이터 로드
        await viewModel.loadBackgroundsAndCarabiners()

        // selectedBackground와 selectedCarabiner 설정
        guard let bundle = viewModel.selectedBundle else { return }

        viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
        viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)

        // 키링 데이터 로드
        guard let carabiner = viewModel.selectedCarabiner else { return }
        keyringDataList = await createKeyringDataList(bundle: bundle, carabiner: carabiner)
    }

    private func createKeyringDataList(bundle: KeyringBundle, carabiner: Carabiner) async -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        for (index, keyringId) in bundle.keyrings.enumerated() {
            guard index < carabiner.maxKeyringCount,
                  keyringId != "none",
                  !keyringId.isEmpty else { continue }

            guard let keyringInfo = await fetchKeyringInfo(keyringId: keyringId) else { continue }

            let customSoundURL: URL? = {
                if keyringInfo.soundId.hasPrefix("https://") || keyringInfo.soundId.hasPrefix("http://") {
                    return URL(string: keyringInfo.soundId)
                }
                return nil
            }()

            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyringInfo.bodyImage,
                soundId: keyringInfo.soundId,
                customSoundURL: customSoundURL,
                particleId: keyringInfo.particleId
            )
            dataList.append(data)
        }

        return dataList
    }

    private func fetchKeyringInfo(keyringId: String) async -> KeyringInfo? {
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
            return nil
        }
    }

    private struct KeyringInfo {
        let id: String
        let bodyImage: String
        let soundId: String
        let particleId: String
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
