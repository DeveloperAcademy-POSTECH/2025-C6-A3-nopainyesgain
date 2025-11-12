//
//  BundleAddKeyringView.swift
//  Keychy
//
//  Created by 김서현 on 10/28/25.
//

import SwiftUI
import SpriteKit
import NukeUI

/// 번들에 키링을 추가하는 뷰
struct BundleAddKeyringView: View {
    // MARK: - Properties

    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel

    @State private var showSelectKeyringSheet = false       // 키링 선택 시트 표시 여부
    @State private var selectedKeyrings: [Int: Keyring] = [:]  // 선택된 키링들 (위치: 키링)
    @State private var keyringOrder: [Int] = []             // 키링 추가 순서
    @State private var selectedPosition = 0                 // 현재 선택된 위치
    @State private var isDeleteButtonSelected = false       // 삭제 버튼 표시 여부
    @State private var isCapturing = false                  // 캡처 진행 상태

    // 키링 선택 시트 그리드 컬럼
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let screenSize = CGSize(width: 390, height: 844)  // 기본 화면 크기
    private let sheetHeightRatio: CGFloat = 0.5               // 시트 높이 비율

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack {
                sceneView(carabiner: viewModel.selectedCarabiner ?? viewModel.carabiners.first!)
                Spacer()
            }

            if showSelectKeyringSheet {
                keyringSelectionSheet
            }

            if isCapturing {
                capturingOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear { fetchData() }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backButton
            nextButton
        }
    }
}

// MARK: - View Components

extension BundleAddKeyringView {
    /// 카라비너 + 키링 씬 뷰
    private func sceneView(carabiner: Carabiner) -> some View {
        VStack {
            ZStack(alignment: .top) {
                let carabinerType = CarabinerType.from(carabiner.carabinerType)

                if carabinerType == .hamburger {
                    hamburgerCarabinerLayers(carabiner: carabiner)
                } else if carabinerType == .plain {
                    plainCarabinerLayers(carabiner: carabiner)
                }

                keyringButtons(carabiner: carabiner)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 햄버거 카라비너 레이어 (뒷면 - 키링 - 앞면)
    private func hamburgerCarabinerLayers(carabiner: Carabiner) -> some View {
        MultiKeyringSceneView(
            keyringDataList: createKeyringDataList(carabiner: carabiner),
            ringType: .basic,
            chainType: .basic,
            backgroundColor: .clear,
            backgroundImageURL: viewModel.selectedBackground?.backgroundImage,
            carabinerBackImageURL: carabiner.carabinerImage[1],
            carabinerFrontImageURL: carabiner.carabinerImage[2],
            carabinerX: carabiner.carabinerX,
            carabinerY: carabiner.carabinerY,
            carabinerWidth: carabiner.carabinerWidth,
            currentCarabinerType: CarabinerType.from(carabiner.carabinerType)
        )
        .id(selectedKeyrings.keys.sorted())
    }

    /// 플레인 카라비너 레이어 (카라비너 - 키링)
    private func plainCarabinerLayers(carabiner: Carabiner) -> some View {
        MultiKeyringSceneView(
            keyringDataList: createKeyringDataList(carabiner: carabiner),
            ringType: .basic,
            chainType: .basic,
            backgroundColor: .clear,
            backgroundImageURL: viewModel.selectedBackground?.backgroundImage,
            carabinerBackImageURL: carabiner.carabinerImage[0],
            carabinerFrontImageURL: nil,
            carabinerX: carabiner.carabinerX,
            carabinerY: carabiner.carabinerY,
            carabinerWidth: carabiner.carabinerWidth,
            currentCarabinerType: CarabinerType.from(carabiner.carabinerType)
        )
        .id(selectedKeyrings.keys.sorted())
    }

    /// 키링 추가 버튼들
    private func keyringButtons(carabiner: Carabiner) -> some View {
        ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
            let position = buttonPosition(index: index, carabiner: carabiner)

            CarabinerAddKeyringButton(
                isSelected: selectedPosition == index,
                hasKeyring: selectedKeyrings[index] != nil,
                action: {
                    selectedPosition = index
                    withAnimation(.easeInOut) {
                        showSelectKeyringSheet = true
                    }
                },
                secondAction: {
                    selectedPosition = index
                    isDeleteButtonSelected = true
                }
            )
            .position(position)
            .overlay(alignment: .top) {
                if isDeleteButtonSelected && selectedPosition == index && selectedKeyrings[index] != nil {
                    deleteButton()
                        .position(x: position.x, y: position.y)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.spring, value: isDeleteButtonSelected)
                }
            }
        }
    }

    /// 키링 선택 시트
    private var keyringSelectionSheet: some View {
        VStack {
            HStack {
                Button {
                    withAnimation(.easeInOut) {
                        showSelectKeyringSheet = false
                    }
                } label: {
                    Image(systemName: "xmark")
                }
                Spacer()
                Text("키링 선택")
                Spacer()
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.keyring, id: \.self) { keyring in
                        keyringCell(keyring: keyring)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20))
        .frame(maxWidth: .infinity)
        .frame(height: screenSize.height * sheetHeightRatio)
        .background(.white100)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom))
        .zIndex(2)
    }

    /// 키링 셀
    private func keyringCell(keyring: Keyring) -> some View {
        Button {
            // 기존 키링이 있으면 순서에서 제거
            if selectedKeyrings[selectedPosition] != nil {
                keyringOrder.removeAll { $0 == selectedPosition }
            }

            // 새 키링 추가 및 순서 기록
            selectedKeyrings[selectedPosition] = keyring
            keyringOrder.append(selectedPosition)

            withAnimation(.easeInOut) {
                showSelectKeyringSheet = false
            }
        } label: {
            VStack {
                CollectionCellView(keyring: keyring)
                    .frame(width: 175, height: 223)
                    .cornerRadius(10)
                    .padding(.bottom, 10)

                Text("\(keyring.name) 키링")
                    .typography(.suit14SB18)
                    .foregroundStyle(.black100)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 175, height: 261)
        .disabled(keyring.status == .packaged || keyring.status == .published)
    }

    /// 삭제 버튼
    private func deleteButton() -> some View {
        HStack(spacing: 0) {
            Spacer()
            Button {
                isDeleteButtonSelected = false
            } label: {
                Text("취소")
                    .typography(.suit16M)
                    .foregroundStyle(.black100)
            }
            Spacer()
            Divider().frame(height: 20)
            Spacer()
            Button {
                selectedKeyrings[selectedPosition] = nil
                keyringOrder.removeAll { $0 == selectedPosition }
                isDeleteButtonSelected = false
            } label: {
                Text("삭제")
                    .typography(.suit16M)
                    .foregroundStyle(.primaryRed)
            }
            Spacer()
        }
        .frame(width: 129, height: 44)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    /// 캡처 중 오버레이
    private var capturingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("이미지 생성 중...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
}

// MARK: - Toolbar

extension BundleAddKeyringView {
    /// 뒤로가기 버튼
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }

    /// 다음 버튼
    private var nextButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("다음") {
                Task {
                    await captureAndSaveScene()
                }
            }
            .disabled(isCapturing)
        }
    }
}

// MARK: - Scene Management

extension BundleAddKeyringView {
    /// 씬 캡처 및 저장
    private func captureAndSaveScene() async {
        guard let carabiner = viewModel.selectedCarabiner,
              let background = viewModel.selectedBackground else {
            print("⚠️ [BundleAddKeyring] 카라비너 또는 배경이 없습니다")
            return
        }

        // 캡처 시작
        await MainActor.run {
            isCapturing = true
            viewModel.selectedKeyringsForBundle = selectedKeyrings
        }

        // 배경 이미지 미리 로드
        guard let _ = try? await StorageManager.shared.getImage(path: background.backgroundImage) else {
            print("❌ [BundleAddKeyring] 배경 이미지 미리 로드 실패")
            await MainActor.run {
                isCapturing = false
            }
            return
        }

        // 캡처용 키링 데이터 생성
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []

        for (index, keyring) in selectedKeyrings.sorted(by: { $0.key < $1.key }) {
            let data = MultiKeyringCaptureScene.KeyringData(
                index: index,
                position: CGPoint(
                    x: carabiner.keyringXPosition[index],
                    y: carabiner.keyringYPosition[index]
                ),
                bodyImageURL: keyring.bodyImage
            )
            keyringDataList.append(data)
        }

        // 카라비너 이미지 추출
        let carabinerType = CarabinerType.from(carabiner.carabinerType)
        let carabinerBackURL: String?
        let carabinerFrontURL: String?

        if carabinerType == .hamburger {
            carabinerBackURL = carabiner.carabinerImage[1]
            carabinerFrontURL = carabiner.carabinerImage[2]
        } else {
            // plain 타입
            carabinerBackURL = carabiner.carabinerImage[0]
            carabinerFrontURL = nil
        }

        // 씬 캡처
        if let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: background.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerX: carabiner.carabinerX,
            carabinerY: carabiner.carabinerY,
            carabinerWidth: carabiner.carabinerWidth,
            customSize: screenSize
        ) {
            await MainActor.run {
                viewModel.bundleCapturedImage = pngData
            }
        } else {
            print("❌ [BundleAddKeyring] 캡처 실패")
        }

        // 캡처 완료 후 다음 화면으로 이동
        await MainActor.run {
            isCapturing = false
            router.push(.bundleNameInputView)
        }
    }
}

// MARK: - Data Fetching

extension BundleAddKeyringView {
    /// 사용자 데이터 가져오기
    private func fetchData() {
        let uid = UserManager.shared.userUID

        viewModel.fetchUserCollectionData(uid: uid) { success in
            if success {
                viewModel.fetchUserKeyrings(uid: uid) { _ in }
            }
        }
    }
}

// MARK: - Helper Methods

extension BundleAddKeyringView {
    /// 버튼 위치 계산 (절대 좌표 그대로 반환)
    private func buttonPosition(index: Int, carabiner: Carabiner) -> CGPoint {
        CGPoint(
            x: carabiner.keyringXPosition[index],
            y: carabiner.keyringYPosition[index]
        )
    }

    /// 키링 데이터 리스트 생성
    private func createKeyringDataList(carabiner: Carabiner) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        // 추가된 순서대로 처리
        for index in keyringOrder {
            guard let keyring = selectedKeyrings[index] else { continue }
            let soundId = keyring.soundId

            // 커스텀 사운드 URL 처리
            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()

            let particleId = keyring.particleId

            // 절대 좌표 사용 (이미 절대 좌표로 저장됨)
            let position = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )

            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: position,
                bodyImageURL: keyring.bodyImage,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: particleId
            )
            dataList.append(data)
        }

        return dataList
    }
}
