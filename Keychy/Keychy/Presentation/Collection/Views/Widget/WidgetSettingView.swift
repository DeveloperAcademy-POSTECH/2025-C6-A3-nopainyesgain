//
//  WidgetSettingView.swift
//  Keychy
//
//  Created by Jini on 10/30/25.
//

import SwiftUI

struct WidgetSettingView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    
    private let steps = WidgetOnboardingStep.steps
    
    var body: some View {
        ScrollView {
            VStack {
                // 단계별 가이드
                ForEach(steps) { step in
                    WidgetOnboardingStepView(step: step)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("위젯 설정")
        .swipeBackGesture(enabled: true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .toolbar {
            backToolbarItem
            customTitleToolbarItem
        }
        .onAppear {
            TabBarManager.hide()
        }
    }
}

extension WidgetSettingView {
    var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                TabBarManager.show()
                router.pop()
            } label: {
                Image(.backIcon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
    }
    
    // 커스텀 타이틀
    var customTitleToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 0) {
                Text("위젯 설정")
                    .typography(.suit16M)
                    .foregroundColor(.gray600)
                
                Text("iOS 26 이상")
                    .typography(.notosans12R)
                    .foregroundColor(.gray400)
            }
        }
    }
}
