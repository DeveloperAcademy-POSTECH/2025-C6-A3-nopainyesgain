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

    @State private var showSelectKeyringSheet: Bool = false
    @State private var selectedKeyrings: [Int: Keyring] = [:]
    @State private var keyringOrder: [Int] = []  // 키링이 추가된 순서 추적
    @State private var selectedPosition: Int = 0
    @State private var carabinerImage: UIImage?
    @State private var isSceneReady: Bool = false
    @State private var isDeleteButtonSelected: Bool = false

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    sceneView(geometry: geometry)
                    Spacer()
                }

                if showSelectKeyringSheet {
                    keyringSelectionSheet(height: geometry.size.height * 0.5)
                }
            }
            .ignoresSafeArea()
            .background(backgroundImage)
            .onAppear {
                fetchData()
                createScene(size: geometry.size, screenWidth: geometry.size.width)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            backButton
            nextButton
        }
    }
}

// MARK: - View Components

extension BundleAddKeyringView {
    /// 배경 이미지
    private var backgroundImage: some View {
        Group {
            if let background = viewModel.selectedBackground {
                LazyImage(url: URL(string: background.backgroundImage)) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else if state.isLoading {
                        Color.clear
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    /// 씬 뷰
    private func sceneView(geometry: GeometryProxy) -> some View {
        VStack {
            ZStack(alignment: .top) {
                // 1층: 뒷 카라비너 이미지 표시
                if let carabiner = viewModel.selectedCarabiner {
                    LazyImage(url: URL(string: carabiner.carabinerImage[1])) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                        
                }

                // 2층: 여러 키링을 하나의 씬에 표시
                if let carabiner = viewModel.selectedCarabiner {
                    MultiKeyringSceneView(
                        keyringDataList: createKeyringDataList(carabiner: carabiner, geometry: geometry),
                        ringType: .basic,
                        chainType: .basic,
                        backgroundColor: .clear
                    )
                    .id(selectedKeyrings.keys.sorted())  // 키링 변경 시 View 재생성
                }
                // 3층 : 앞 카라비너 이미지 표시 (햄버거 구조)
                if let carabiner = viewModel.selectedCarabiner {
                    LazyImage(url: URL(string: carabiner.carabinerImage[2])) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                }
                
                // 4층: 버튼 오버레이 (가장 위)
                if isSceneReady, let carabiner = viewModel.selectedCarabiner {
                    keyringButtons(carabiner: carabiner, geometry: geometry)
                }
            }
            .padding(.top, 60) // 상단 여유 공간 추가
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 키링 추가 버튼들
    private func keyringButtons(carabiner: Carabiner, geometry: GeometryProxy) -> some View {
        ForEach(0..<carabiner.maxKeyringCount, id: \.self) { index in
            let position = buttonPosition(index: index, carabiner: carabiner, geometry: geometry)

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
                        .position(x: position.x, y: position.y - 49)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.spring, value: isDeleteButtonSelected)
                }
            }
        }
    }

    /// 키링 선택 시트
    private func keyringSelectionSheet(height: CGFloat) -> some View {
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
        .frame(height: height)
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
            // 이미 키링이 있는 위치면 순서에서 제거 (교체)
            if selectedKeyrings[selectedPosition] != nil {
                keyringOrder.removeAll { $0 == selectedPosition }
            }

            // 키링 추가 및 순서 기록
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
                keyringOrder.removeAll { $0 == selectedPosition }  // 순서에서도 제거
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
}

// MARK: - Toolbar

extension BundleAddKeyringView {
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }

    private var nextButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("다음") {
                saveScene()
                router.push(.bundleNameInputView)
            }
        }
    }
}

// MARK: - Scene Management

extension BundleAddKeyringView {

    /// 씬 생성
    private func createScene(size: CGSize, screenWidth: CGFloat) {
        guard let carabiner = viewModel.selectedCarabiner,
              let backImageURL = carabiner.carabinerImage[safe: 1], let frontImageURL = carabiner.carabinerImage[safe: 2] else {
            return
        }

        isSceneReady = false

        Task {
            guard let image = try? await StorageManager.shared.getImage(path: backImageURL) else {
                print("카라비너 이미지 로드 실패")
                return
            }

            await MainActor.run {
                self.carabinerImage = image
                self.isSceneReady = true
            }
        }
    }

    /// 씬 저장
    private func saveScene() {
        viewModel.selectedKeyringsForBundle = selectedKeyrings
    }
}

// MARK: - Data Fetching

extension BundleAddKeyringView {
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
    /// 버튼 위치 계산
    private func buttonPosition(index: Int, carabiner: Carabiner, geometry: GeometryProxy) -> CGPoint {
        // carabiner의 keyringXPosition, keyringYPosition은 화면 비율 (0.0 ~ 1.0)
        let x = carabiner.keyringXPosition[index] * geometry.size.width
        // 상단 패딩(60pt) 고려하여 Y 위치 조정
        let y = carabiner.keyringYPosition[index] * geometry.size.height + 60

        return CGPoint(x: x, y: y)
    }

    /// KeyringData 리스트 생성
    private func createKeyringDataList(carabiner: Carabiner, geometry: GeometryProxy) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        // 추가된 순서대로 처리
        for index in keyringOrder {
            guard let keyring = selectedKeyrings[index] else { continue }
            let soundId = keyring.soundId
            // 사운드 정보 추출


            // 커스텀 사운드 URL 처리
            // soundId가 URL 형식이면 해당 URL 사용, 아니면 nil
            let customSoundURL: URL? = {
                    return URL(string: soundId)
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                }
                return nil
            }()

            // 파티클 정보 추출
            let particleId = keyring.particleId

            let relativePosition = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )
            
            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: relativePosition,  // 비율 좌표 직접 전달
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

#Preview {
    BundleAddKeyringView(router: NavigationRouter(), viewModel: CollectionViewModel())
}
