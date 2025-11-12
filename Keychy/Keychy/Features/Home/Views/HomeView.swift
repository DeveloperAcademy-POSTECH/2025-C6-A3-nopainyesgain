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

    var body: some View {
        ZStack(alignment: .top) {
            // 메인 씬 뷰
            if let bundle = collectionViewModel.selectedBundle,
               let carabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner),
               let background = collectionViewModel.selectedBackground {

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
        
                ///  이 코드는 다음 조건이 하나라도 변경되면 MultiKeyringSceneView를 완전히 재생성합니다:
                ///- background.id 변경 (배경 이미지 변경)
                ///- carabiner.id 변경 (카라비너 변경)
                ///- keyringDataList의 인덱스 구성 변경 (키링 추가/삭제/순서 변경)
                .id("\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map(\.index).sorted())")
            } else {
                Color.clear.ignoresSafeArea()
            }

            // 상단 버튼들
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
            await loadMainBundle()
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadMainBundle() async {
        let uid = UserManager.shared.userUID
        guard !uid.isEmpty else { return }

        // 배경 및 카라비너 데이터 로드
        await collectionViewModel.loadBackgroundsAndCarabiners()

        // 번들 목록 로드
        await withCheckedContinuation { continuation in
            collectionViewModel.fetchAllBundles(uid: uid) { _ in
                continuation.resume()
            }
        }

        // Main bundle 설정
        if let mainBundle = collectionViewModel.sortedBundles.first(where: { $0.isMain }) {
            collectionViewModel.selectedBundle = mainBundle
        } else if let firstBundle = collectionViewModel.sortedBundles.first {
            collectionViewModel.selectedBundle = firstBundle
        } else {
            return
        }

        // Background와 Carabiner 설정
        guard let bundle = collectionViewModel.selectedBundle else { return }
        collectionViewModel.selectedBackground = collectionViewModel.resolveBackground(from: bundle.selectedBackground)
        collectionViewModel.selectedCarabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner)

        // 키링 데이터 로드
        guard let carabiner = collectionViewModel.selectedCarabiner else { return }
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
