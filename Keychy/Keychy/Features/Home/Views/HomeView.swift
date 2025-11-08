//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import NukeUI

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    @State var collectionViewModel: CollectionViewModel
    @Namespace private var unionNamespace
    
    var body: some View {
        ZStack(alignment: .top) {
            // Bundle Scene - main bundle만 표시
            BundleDetailView(router: router, viewModel: collectionViewModel)
            
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
            // 홈 진입 시 main bundle 로드 및 설정
            await loadMainBundle()
        }
    }
    
    // MARK: - Main Bundle Loading
    @MainActor
    private func loadMainBundle() async {
        let uid = UserManager.shared.userUID
        guard !uid.isEmpty else { return }
        
        // 번들 목록 로드
        await withCheckedContinuation { continuation in
            collectionViewModel.fetchAllBundles(uid: uid) { success in
                continuation.resume()
            }
        }
        
        // main bundle을 selectedBundle로 설정
        if let mainBundle = collectionViewModel.sortedBundles.first(where: { $0.isMain }) {
            collectionViewModel.selectedBundle = mainBundle
            print("[HomeView] Main bundle selected: \(mainBundle.name)")
        } else if let firstBundle = collectionViewModel.sortedBundles.first {
            // main bundle이 없으면 첫 번째 bundle 선택
            collectionViewModel.selectedBundle = firstBundle
            print("[HomeView] First bundle selected: \(firstBundle.name)")
        } else {
            print("[HomeView] No bundle found")
        }
    }
}
