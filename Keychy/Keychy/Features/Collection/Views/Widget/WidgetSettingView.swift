//
//  WidgetSettingView.swift
//  Keychy
//
//  Created by Jini on 10/30/25.
//

import SwiftUI

struct WidgetSettingView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    
    var body: some View {
        VStack {
            Text("준비 중")
        }
        .navigationTitle("위젯 설정")
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            backToolbarItem
        }
        .onAppear {
            hideTabBar()
        }
        .onDisappear {
            showTabBar()
        }
        
    }
    
    // MARK: - 탭바 제어
    func hideTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = true
            }
        }
    }
    
    func showTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = false
            }
        }
    }
}

extension WidgetSettingView {
    var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image("backIcon")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
    }
}


