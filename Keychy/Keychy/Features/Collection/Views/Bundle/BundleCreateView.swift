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
                selectedView(
                    bg: <#T##BackgroundViewData#>,
                    cb: <#T##CarabinerViewData#>,
                    geometry: <#T##GeometryProxy#>
                )
                
            }
        }
    }
}

// MARK: - 배경, 카라비너 뷰
extension BundleCreateView {
    private func selectedView(bg: BackgroundViewData, cb: CarabinerViewData, geometry: GeometryProxy) -> some View {
        
        return ZStack {
            
            // 배경화면 이미지
            LazyImage(url: URL(string: bg.background.backgroundImage)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                }
            }
            
            // 카라비너 이미지
            LazyImage(url: URL(string: cb.carabiner.carabinerImage[0])) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .position(x: cb.carabiner.carabinerX, y: cb.carabiner.carabinerY)
                }
            }
            
        }
    }
}


// MARK: - 데이터 가져오는 메서드
