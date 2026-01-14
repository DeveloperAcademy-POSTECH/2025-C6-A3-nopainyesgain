//
//  BundleInventoryView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import SwiftUI

struct BundleInventoryView<Route: BundleRoute>: View {
    @Bindable var router: NavigationRouter<Route>
    @State var collectionVM: CollectionViewModel
    @State var bundleVM: BundleViewModel

    @State var isNavigatingDeeper: Bool = false
    @State private var hasNetworkError: Bool = false
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12.5),
        GridItem(.flexible(), spacing: 12.5)
    ]
    
    var body: some View {
        Group {
            if hasNetworkError {
                // 네트워크 에러: 오버레이 형태
                ZStack(alignment: .top) {
                    Color.white
                        .ignoresSafeArea()

                    NoInternetView(topPadding: getSafeAreaTop() + 10, onRetry: {
                        await retryFetchData()
                    })
                    .ignoresSafeArea()

                    VStack {
                        customNavigationBar
                        Spacer()
                    }
                }
            } else {
                // 정상 상태: 기존 ZStack 형태
                ZStack(alignment: .top) {
                    bundleGrid()

                    customNavigationBar
                }
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .withToast(position: .default)
        .onAppear {
            // 네트워크 체크
            guard NetworkManager.shared.isConnected else {
                hasNetworkError = true
                isNavigatingDeeper = false
                collectionVM.hideTabBar()
                return
            }

            hasNetworkError = false
            isNavigatingDeeper = false
            collectionVM.hideTabBar()

            // 현재 로그인된 유저의 뭉치 로드
            let uid = UserManager.shared.userUID
            guard !uid.isEmpty else { return }
            bundleVM.fetchAllBundles(uid: uid) { success in
                if !success {
                    print("뭉치 로드 실패")
                }
            }
        }
        .onDisappear {
            if !isNavigatingDeeper {
                collectionVM.showTabBar()
            }
        }
        .navigationBarBackButtonHidden(true)
        .scrollIndicators(.hidden)
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
                    ForEach(bundleVM.sortedBundles, id: \.documentId) { bundle in
                        Button {
                            // 네트워크 체크
                            guard NetworkManager.shared.isConnected else {
                                ToastManager.shared.show()
                                return
                            }

                            // 선택한 번들 설정
                            bundleVM.selectedBundle = bundle
                            // 번들에 저장된 id(String)를 실제 모델로 해석하여 선택 상태에 반영
                            bundleVM.selectedBackground = bundleVM.resolveBackground(from: bundle.selectedBackground)
                            bundleVM.selectedCarabiner = bundleVM.resolveCarabiner(from: bundle.selectedCarabiner)

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

// MARK: - 네트워크 재시도
extension BundleInventoryView {
    func retryFetchData() async {
        await MainActor.run {
            // 네트워크 재체크
            guard NetworkManager.shared.isConnected else {
                return
            }

            hasNetworkError = false

            // 현재 로그인된 유저의 뭉치 로드
            let uid = UserManager.shared.userUID
            guard !uid.isEmpty else { return }
            bundleVM.fetchAllBundles(uid: uid) { success in
                if !success {
                    print("뭉치 로드 실패")
                }
            }
        }
    }
}
