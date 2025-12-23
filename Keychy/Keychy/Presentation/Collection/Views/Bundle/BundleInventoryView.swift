//
//  BundleInventoryView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import SwiftUI

struct BundleInventoryView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var viewModel: CollectionViewModel
    
    @State var isNavigatingDeeper: Bool = false
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12.5),
        GridItem(.flexible(), spacing: 12.5)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            bundleGrid()
            
            customNavigationBar
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            isNavigatingDeeper = false
            viewModel.hideTabBar()
        }
        .onDisappear {
            if !isNavigatingDeeper {
                viewModel.showTabBar()
            }
        }
        .navigationBarBackButtonHidden(true)
        .scrollIndicators(.hidden)
        .onAppear {
            // 현재 로그인된 유저의 뭉치 로드
            let uid = UserManager.shared.userUID
            guard !uid.isEmpty else { return }
            viewModel.fetchAllBundles(uid: uid) { success in
                if !success {
                    print("뭉치 로드 실패")
                }
            }
        }
    }
}

// MARK: - 툴바
extension BundleInventoryView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center : {
            Text("뭉치함")
        } trailing: {
            PlusToolbarButton {
                isNavigatingDeeper = true
                router.push(.bundleCreateView)
            }
        }
    }
}

// MARK: - 그리드 뷰
extension BundleInventoryView {
    private func bundleGrid() -> some View {
        // 동그라미 기기라면 추가적인 패딩값을 줍니다
        var morePadding: CGFloat = 0
        if getBottomPadding(34) == 0 {
            morePadding = 40
        }
        return GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 11) {
                    ForEach(viewModel.sortedBundles, id: \.self) { bundle in
                        Button {
                            // 선택한 번들 설정
                            viewModel.selectedBundle = bundle
                            // 번들에 저장된 id(String)를 실제 모델로 해석하여 선택 상태에 반영
                            viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
                            viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)
                            
                            // 상세 화면으로 이동
                            isNavigatingDeeper = true
                            router.push(.bundleDetailView)
                        } label: {
                            KeyringBundleItem(bundle: bundle)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, geometry.safeAreaInsets.top + 80 + morePadding) // safe area + 네비 바 높이 + 여백
            }
        }
        
    }
}

//MARK: - 뷰 lifeCycle 관리
extension BundleInventoryView {
    func handleViewAppear() {
        isNavigatingDeeper = false
        viewModel.hideTabBar()
    }
    
    func handleViewDisappear() {
        if !isNavigatingDeeper {
            viewModel.showTabBar()
        }
    }
}
