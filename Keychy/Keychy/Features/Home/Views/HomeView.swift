//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//
// 홈 화면 - 메인 뭉치의 키링들을 3D 씬으로 표시

import SwiftUI
import NukeUI
import FirebaseFirestore

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>

    @Bindable var userManager: UserManager

    @State var collectionViewModel: CollectionViewModel

    /// 배경 로드 완료 콜백
    var onBackgroundLoaded: (() -> Void)? = nil

    /// GlassEffect 애니메이션을 위한 네임스페이스
    @Namespace private var unionNamespace

    /// MultiKeyringScene에 전달할 키링 데이터 리스트
    @State private var keyringDataList: [MultiKeyringScene.KeyringData] = []

    /// 씬 준비 완료 여부
    @State private var isSceneReady = false

    /// 로딩 알림 투명도
    @State private var loadingAlertOpacity: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
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
                    carabinerX: carabiner.carabinerX,
                    carabinerY: carabiner.carabinerY,
                    carabinerWidth: carabiner.carabinerWidth,
                    currentCarabinerType: carabiner.type,
                    onBackgroundLoaded: onBackgroundLoaded,
                    onAllKeyringsReady: {
                        // 흐려지면서 소멸
                        withAnimation(.easeOut(duration: 0.3)) {
                            loadingAlertOpacity = 0
                        }

                        // 애니메이션 완료 후 상태 변경
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isSceneReady = true
                        }
                    }
                )
                .ignoresSafeArea()
                /// 씬 재생성 조건을 위한 ID 설정
                /// 배경, 카라비너, 키링 구성이 변경되면 씬을 완전히 재생성
                .id("\(background.id ?? "")_\(carabiner.id ?? "")_\(keyringDataList.map(\.index).sorted())")
            } else {
                // 데이터 로딩 중
                Color.clear.ignoresSafeArea()
            }

            // 상단 네비게이션 버튼들
            navigationButtons

            // 로딩 알림 (씬 준비 전까지 표시)
            if !isSceneReady {
                ZStack {
                    // 블러 배경
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(Color.black20)
                        .ignoresSafeArea()

                    // 로딩 알림
                    LoadingAlert(type: .longWithKeychy, message: "키링 뭉치를 불러오고 있어요")
                        .opacity(loadingAlertOpacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // 뷰가 나타날 때 메인 뭉치 데이터 로드
            await loadMainBundle()
        }
        .onChange(of: keyringDataList) { _, _ in
            // 키링 데이터가 변경되면 씬 준비 상태 초기화
            isSceneReady = false
            loadingAlertOpacity = 1.0
        }
    }
}

// MARK: - View Components
extension HomeView {
    /// 상단 네비게이션 버튼들
    private var navigationButtons: some View {
        HStack(spacing: 10) {
            Spacer()

            // 뭉치 목록 버튼
            Button {
                router.push(.bundleInventoryView)
            } label: {
                Image(.bundleIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .frame(width: 44, height: 44)
            .glassEffect()

            // 알림 및 마이페이지 버튼 그룹
            GlassEffectContainer {
                HStack(spacing: 0) {
                    Button {
                        router.push(.alarmView)
                    } label: {
                        Image(.alarmIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    .frame(width: 44, height: 44)
                    .glassEffect()
                    .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)

                    Button {
                        router.push(.myPageView)
                    } label: {
                        Image(.myPageIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)

                    }
                    .frame(width: 44, height: 44)
                    .glassEffect()
                    .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                }
            }
        }
        .padding(.horizontal, 20)
        .tint(.white.opacity(0))
    }
}

// MARK: - Data Loading
extension HomeView {
    /// 메인 뭉치 데이터를 로드하고 뷰 상태를 초기화
    /// 1. 사용자의 모든 뭉치 목록을 가져옴
    /// 2. 메인으로 설정된 뭉치를 찾아 선택
    /// 3. 선택된 뭉치의 키링들을 Firestore에서 가져와 KeyringData 리스트 생성
    @MainActor
    private func loadMainBundle() async {
        let uid = UserManager.shared.userUID
        guard !uid.isEmpty else { return }

        // 1. 배경 및 카라비너 데이터 로드
        await collectionViewModel.loadBackgroundsAndCarabiners()

        // 2. 번들 목록 로드
        await withCheckedContinuation { continuation in
            collectionViewModel.fetchAllBundles(uid: uid) { _ in
                continuation.resume()
            }
        }

        // 3. 메인 뭉치 설정 (isMain == true인 뭉치, 없으면 첫 번째 뭉치)
        if let mainBundle = collectionViewModel.sortedBundles.first(where: { $0.isMain }) {
            collectionViewModel.selectedBundle = mainBundle
        } else if let firstBundle = collectionViewModel.sortedBundles.first {
            collectionViewModel.selectedBundle = firstBundle
        } else {
            // 번들이 하나도 없는 경우 - 스플래시 즉시 종료
            onBackgroundLoaded?()
            return
        }

        // 4. 선택된 뭉치의 배경과 카라비너 설정
        guard let bundle = collectionViewModel.selectedBundle else { return }
        collectionViewModel.selectedBackground = collectionViewModel.resolveBackground(from: bundle.selectedBackground)
        collectionViewModel.selectedCarabiner = collectionViewModel.resolveCarabiner(from: bundle.selectedCarabiner)

        // 5. 키링 데이터 생성
        guard let carabiner = collectionViewModel.selectedCarabiner else { return }
        keyringDataList = await createKeyringDataList(bundle: bundle, carabiner: carabiner)
    }

    /// 뭉치의 키링들을 MultiKeyringScene.KeyringData 배열로 변환
    /// - Parameters:
    ///   - bundle: 현재 뭉치
    ///   - carabiner: 선택된 카라비너 (위치 정보 제공)
    /// - Returns: 3D 씬에서 사용할 KeyringData 배열
    private func createKeyringDataList(bundle: KeyringBundle, carabiner: Carabiner) async -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        for (index, keyringId) in bundle.keyrings.enumerated() {
            // 유효하지 않은 키링 ID 필터링
            guard index < carabiner.maxKeyringCount,
                  keyringId != "none",
                  !keyringId.isEmpty else { continue }

            // Firebase에서 키링 정보 가져오기
            guard let keyringInfo = await fetchKeyringInfo(keyringId: keyringId) else { continue }

            // 커스텀 사운드 URL 처리 (HTTP/HTTPS로 시작하는 경우)
            let customSoundURL: URL? = {
                if keyringInfo.soundId.hasPrefix("https://") || keyringInfo.soundId.hasPrefix("http://") {
                    return URL(string: keyringInfo.soundId)
                }
                return nil
            }()

            // KeyringData 생성
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

    /// Firestore에서 키링 정보를 가져옴
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

    /// Firestore에서 가져온 키링 정보를 담는 구조체
    private struct KeyringInfo {
        let id: String
        let bodyImage: String
        let soundId: String
        let particleId: String
    }
}
