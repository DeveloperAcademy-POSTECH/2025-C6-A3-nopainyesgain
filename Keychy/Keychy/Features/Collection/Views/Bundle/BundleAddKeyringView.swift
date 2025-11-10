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
                    sceneView(geometry: geometry, carabiner: (viewModel.selectedCarabiner ?? viewModel.carabiners.first)!)
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
    private func sceneView(geometry: GeometryProxy, carabiner: Carabiner) -> some View {
        VStack {
            ZStack(alignment: .top) {
                // 카라비너 타입이 햄버거인 경우
                if CarabinerType.from(carabiner.carabinerType) == .hamburger {
                    // 1층: 뒷 카라비너 이미지 표시
                    LazyImage(url: URL(string: carabiner.carabinerImage[1])) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                    
                    // 2층: 여러 키링을 하나의 씬에 표시
                    MultiKeyringSceneView(
                        keyringDataList: createKeyringDataList(carabiner: carabiner, geometry: geometry),
                        ringType: .basic,
                        chainType: .basic,
                        backgroundColor: .clear,
                        currentCarabinerType: CarabinerType.from(carabiner.carabinerType)
                    )
                    .id(selectedKeyrings.keys.sorted())  // 키링 변경 시 View 재생성
                    
                    // 3층 : 앞 카라비너 이미지 표시 (햄버거 구조)
                    LazyImage(url: URL(string: carabiner.carabinerImage[2])) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                    
                    // 4층: 버튼 오버레이 (가장 위)
                    keyringButtons(carabiner: carabiner, geometry: geometry)
                }
                // 기본 카라비너 타입일 때
                else if CarabinerType.from(carabiner.carabinerType) == .plain {
                    
                    // 1층 : 카라비너 이미지
                    LazyImage(url: URL(string: carabiner.carabinerImage[0])) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                    // 2층 : 키링 배치
                    MultiKeyringSceneView(
                        keyringDataList: createKeyringDataList(
                            carabiner: carabiner,
                            geometry: geometry
                        ),
                        currentCarabinerType: CarabinerType.from(carabiner.carabinerType)
                    )
                    .id(selectedKeyrings.keys.sorted())
                }
                // 3층 : +버튼
                keyringButtons(carabiner: carabiner, geometry: geometry)
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
        let y = carabiner.keyringYPosition[index] * geometry.size.height
        
        return CGPoint(x: x, y: y)
    }
    
    /// KeyringData 리스트 생성
    private func createKeyringDataList(carabiner: Carabiner, geometry: GeometryProxy) -> [MultiKeyringScene.KeyringData] {
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
            
            // 파티클 정보 추출
            let particleId = keyring.particleId
            
            // 버튼과 동일한 위치 계산 방식 사용
            let absolutePosition = buttonPosition(index: index, carabiner: carabiner, geometry: geometry)
            let relativePosition = CGPoint(
                x: absolutePosition.x / geometry.size.width,
                y: absolutePosition.y / geometry.size.height
            )
            
            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: relativePosition,  // 버튼 위치와 동일한 비율 좌표
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
