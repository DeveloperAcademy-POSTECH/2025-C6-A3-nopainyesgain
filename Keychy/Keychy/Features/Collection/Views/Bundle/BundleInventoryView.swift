//
//  BundleInventoryView.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import SwiftUI

struct BundleInventoryView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
#if DEBUG
    @State private var showCachedBundlesDebug = false
#endif
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13)
    ]
    
    var body: some View {
        VStack {
            bundleGrid
        }
        .padding(.horizontal, 16)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            backToolbarItem
#if DEBUG
            debugToolbarItem
#endif
            nextToolbarItem
            
        }
        .padding(.top, 20)
        .navigationBarBackButtonHidden(true)
#if DEBUG
        .sheet(isPresented: $showCachedBundlesDebug) {
            CachedBundlesDebugView()
        }
#endif
        .navigationTitle("뭉치함")
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
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
            }
        }
    }
    
    private var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("+") {
                // action
            }
        }
    }
    
#if DEBUG
    private var debugToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showCachedBundlesDebug = true
                BundleImageCache.shared.printAllCachedFiles()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    Image(systemName: "photo.stack")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
        }
    }
#endif
}

// MARK: - 그리드 뷰
extension BundleInventoryView {
    private var bundleGrid: some View {
        Group {
            if viewModel.sortedBundles.isEmpty {
                emptyContentView
                
                Spacer()
                
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(viewModel.sortedBundles, id: \.self) { bundle in
                            Button {
                                // 선택한 번들 설정
                                viewModel.selectedBundle = bundle
                                // 번들에 저장된 id(String)를 실제 모델로 해석하여 선택 상태에 반영
                                viewModel.selectedBackground = viewModel.resolveBackground(from: bundle.selectedBackground)
                                viewModel.selectedCarabiner = viewModel.resolveCarabiner(from: bundle.selectedCarabiner)
                                
                                // 상세 화면으로 이동
                                router.push(.bundleDetailView)
                            } label: {
                                KeyringBundleItem(bundle: bundle)
                            }
                        }
                    }
                }
            }
        }
    }
}
    
extension BundleInventoryView {
    /// 빈 콘텐츠 뷰
    private var emptyContentView: some View {
        VStack {
            
            Spacer()
                .frame(height: 240)
            
            Image("EmptyViewIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 124)
            
            Text("뭉치를 생성해 주세요")
                .typography(.suit15R)
                .padding(.leading, 10)
        }
    }
}
