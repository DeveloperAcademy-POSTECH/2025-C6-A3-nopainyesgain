//
//  BundleCreateView.swift
//  Keychy
//
//  Created by 김서현 on 11/12/25.
//

import SwiftUI
import NukeUI
import SceneKit
import FirebaseFirestore

struct BundleCreateView: View {
    
    //MARK: - 프로퍼티들
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    /// 선택한 카테고리 : "Background" 또는 "Carabiner"
    @State private var selectedCategory: String = ""
    
    // 선택한 배경과 카라비너
    @State private var selectedBackground: BackgroundViewData?
    @State private var selectedCarabiner: CarabinerViewData?
    
    // 시트 활성화 상태
    @State private var showBackgroundSheet: Bool = false
    @State private var showCarabinerSheet: Bool = false
    
    // 임시 초기값
    @State private var sheetHeight: CGFloat = 360
    private let sheetHeightRatio: CGFloat = 0.5
    
    // 구매 시트
    @State var showPurchaseSheet = false
    
    // 구매 처리 상태
    @State private var isPurchasing = false
    
    // 구매 Alert 애니메이션
    @State var showPurchaseSuccessAlert = false
    @State var purchasesSuccessScale: CGFloat = 0.3
    @State var showPurchaseFailAlert = false
    @State var purchaseFailScale: CGFloat = 0.3
    
    
    // 공통 그리드 컬럼 (배경, 카라비너, 키링 모두 동일)
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    //MARK: 메인 뷰
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // 배경과 카라비너가 모두 선택되었을 때만 화면 표시
                // 초기 화면 진입 시 기본 배경, 기본 카라비너를 선택해주긴 하지만 앱 크래시 방지용으로 넣어둡니다
                if let background = selectedBackground,
                   let carabiner = selectedCarabiner {
                    selectedView(
                        bg: background,
                        cb: carabiner,
                        geometry: geo
                    )
                    
                    sheetContent(geo: geo)
                } else {
                    // 로딩 중일 때
                    // 기본 배경 이미지와 로딩 중 애니메이션
                    Image(.greenBackground)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                        Image(.introTypo)
                            .resizable()
                            .scaledToFit()
                        Text("로딩 중이에요")
                        Spacer()
                    }
                }
            }
        }
        .task {
            await initializeData()
        }
        .onAppear {
            // 초기에 배경 시트를 보여줌
            showBackgroundSheet = true
        }
        // 선택 타입이 배경화면이면 카라비너 시트는 닫고, 카라비너 열리면 배경화면은 닫힘
        .onChange(of: showBackgroundSheet) { oldValue, newValue in
            if newValue {
                showCarabinerSheet = false
            }
        }
        .onChange(of: showCarabinerSheet) { oldValue, newValue in
            if newValue {
                showBackgroundSheet = false
            }
        }
    }

}

//MARK: - 시트 뷰
extension BundleCreateView {
    private func sheetContent(geo: GeometryProxy) -> some View {
        Group {
            // 배경 시트
            if showBackgroundSheet {
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 8) {
                        editBackgroundButton
                        editCarabinerButton
                        Spacer()
                    }
                    .padding(.leading, 18)
                    .padding(.bottom, 10)
                    BundleItemCustomSheet(
                        sheetHeight: $sheetHeight,
                        content: selectBackgroundSheet(geo: geo),
                        screenHeight: geo.size.height
                    )
                }
            }
            
            // 카라비너 시트
            if showCarabinerSheet {
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 8) {
                        editBackgroundButton
                        editCarabinerButton
                        Spacer()
                    }
                    .padding(.leading, 18)
                    .padding(.bottom, 10)
                    BundleItemCustomSheet(
                        sheetHeight: $sheetHeight,
                        content: selectCarabinerSheet(geo: geo),
                        screenHeight: geo.size.height
                    )
                }
            }
        }
    }
}

// MARK: - 배경, 카라비너 뷰
extension BundleCreateView {
    private func selectedView(bg: BackgroundViewData, cb: CarabinerViewData, geometry: GeometryProxy) -> some View {
        ZStack {
            // 배경화면 이미지
            LazyImage(url: URL(string: bg.background.backgroundImage)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                }
            }
            
            // 카라비너 이미지 - MultiKeyringScene처럼 상대적 위치로 배치
            carabinerImageView(carabiner: cb.carabiner, containerSize: geometry.size)
        }
    }
    
    /// MultiKeyringScene처럼 상대적 위치로 카라비너 배치
    private func carabinerImageView(carabiner: Carabiner, containerSize: CGSize) -> some View {
        LazyImage(url: URL(string: carabiner.carabinerImage[0])) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: carabiner.carabinerWidth)
                    .offset(
                        // MultiKeyringScene과 동일한 방식으로 상대적 위치 계산
                        x: carabiner.carabinerX - containerSize.width/2 + carabiner.carabinerWidth/2,
                        y: carabiner.carabinerY - containerSize.height/2
                    )
            }
            // 로딩 중에는 아무것도 표시하지 않음
        }
    }
}



// MARK: - 데이터 가져오는 메서드
extension BundleCreateView {
    
    /// 초기 데이터 로딩
    private func initializeData() async {
        // 사용자가 소유한 배경과 카라비너 데이터를 가져옴
        await loadUserOwnedItems()
    }
    
    /// 사용자가 소유한 배경과 카라비너 아이템들을 로드
    private func loadUserOwnedItems() async {
        guard let currentUser = UserManager.shared.currentUser else {
            return
        }
        
        // 배경 데이터 로드
        await withCheckedContinuation { continuation in
            viewModel.fetchAllBackgrounds { _ in
                // 가장 첫 번째 배경을 기본으로 선택
                if self.selectedBackground == nil {
                    self.selectedBackground = viewModel.backgroundViewData.first
                }
                
                continuation.resume()
            }
        }
        
        // 카라비너 데이터 로드
        await withCheckedContinuation { continuation in
            viewModel.fetchAllCarabiners { _ in
                // 가장 첫 번째 카라비너를 기본으로 선택
                if self.selectedCarabiner == nil {
                    self.selectedCarabiner = viewModel.carabinerViewData.first
                }
                
                continuation.resume()
            }
        }
    }
}

// MARK: - 시트
extension BundleCreateView {
    /// 배경 선택 시트
    private func selectBackgroundSheet(geo: GeometryProxy) -> some View {
        SelectBackgroundSheet(
            geo: geo,
            viewModel: viewModel,
            selectedBG: selectedBackground,
            onBackgroundTap: { bg in
                selectedBackground = bg
            }
        )
    }
    
    /// 카라비너 선택 시트
    private func selectCarabinerSheet(geo: GeometryProxy) -> some View {
        SelectCarabinerSheet(
            geo: geo,
            viewModel: viewModel,
            selectedCarabiner: selectedCarabiner,
            onCarabinerTap: { carabiner in
                selectedCarabiner = carabiner
            }
        )
    }
}

// MARK: - 하단 버튼
extension BundleCreateView {
    private var editBackgroundButton: some View {
        Button {
            // 배경 시트 열기
            showBackgroundSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showBackgroundSheet ? .backgroundIconWhite100 : .backgroundIconGray600)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 23.96, height: 25.8)
                Text("배경")
                    .typography(.suit9SB)
                    .foregroundStyle(showBackgroundSheet ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(showBackgroundSheet ? .main500 : .white100)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var editCarabinerButton: some View {
        Button {
            // 카라비너 시트 열기
            showCarabinerSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showCarabinerSheet ? .carabinerIconWhite100 : .carabinerIconGray600)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26.83, height: 23)
                Text("카라비너")
                    .typography(.suit9SB)
                    .foregroundStyle(showCarabinerSheet ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(showCarabinerSheet ? .main500 : .white100)
            )
        }
        .buttonStyle(.plain)
    }
}
