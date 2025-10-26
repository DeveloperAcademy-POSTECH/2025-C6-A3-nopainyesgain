//
//  KeyringCompleteView.swift
//  KeytschPrototype
//
//  키링 완성 화면
//  - 모든 템플릿에서 공통으로 사용 가능
//

import SwiftUI
import SpriteKit

struct KeyringCompleteView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: VM
    let navigationTitle: String

    var body: some View {
        VStack {
            keyringScene
            keyringInfo
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(navigationTitle)
        .toolbar {
            backToolbarItem
        }
    }
}

// MARK: - KeyringScene Section
extension KeyringCompleteView {
    private var keyringScene: some View {
        KeyringSceneView(viewModel: viewModel)
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, minHeight: 500)
    }
}

//MARK: - 툴바
extension KeyringCompleteView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                router.reset()
            }) {
                Image(systemName: "xmark")
            }
        }
    }
}

// MARK: - 키링 정보 뷰
extension KeyringCompleteView {
    private var keyringInfo: some View {
        VStack {
            Text(viewModel.nameText)
            Text(formattedDate(date: viewModel.createdAt))
            Text(viewModel.memoText)
        }
    }

    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: date)
    }
}
