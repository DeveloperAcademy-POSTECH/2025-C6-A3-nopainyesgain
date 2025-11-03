//
//  KeyringInfoInputView.swift
//  KeytschPrototype
//
//  키링 정보 입력 화면
//  - 모든 템플릿에서 공통으로 사용 가능
//

import SwiftUI
import SpriteKit
import Combine
import FirebaseFirestore

struct KeyringInfoInputView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: VM
    let navigationTitle: String
    let nextRoute: WorkshopRoute

    // UserManager 주입
    var userManager: UserManager = UserManager.shared

    // Firebase User의 tags 사용
    var availableTags: [String] {
        userManager.currentUser?.tags ?? []
    }

    // MARK: - State Properties
    @State var textCount: Int = 0
    @State var memoTextCount: Int = 0
    @State var showAddTagAlert: Bool = false
    @State var showTagNameAlreadyExistsToast: Bool = false
    @State var showTagNameEmptyToast: Bool = false
    @State var newTagName: String = ""
    @State var keyboardHandler = KeyboardResponder()
    @State var measuredSheetHeight: CGFloat = 395
    @State var sheetDetent: PresentationDetent = .height(76)
    @State var showSheet: Bool = true
    @FocusState var isFocused: Bool

    // MARK: - Body
    var body: some View {
        ZStack {
            ZStack {
                Color.gray50
                    .ignoresSafeArea()

                keyringScene
                    .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()
            .navigationTitle(navigationTitle)
            .navigationBarBackButtonHidden(true)
            .interactiveDismissDisabled(true)
            .sheet(isPresented: $showSheet) {
                infoSheet
                    .presentationDetents([.height(76), .height(measuredSheetHeight)], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(measuredSheetHeight)))
                    .interactiveDismissDisabled()
                    .onAppear {
                        sheetDetent = .height(measuredSheetHeight)
                    }
            }
            .toolbar {
                backToolbarItem
                nextToolbarItem
            }
            .dismissKeyboardOnTap()

            // Alert overlay (sheet 닫혔을 때만 표시)
            if showAddTagAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                addNewTagAlertView
                    .padding(.horizontal, 25)
            }
        }
    }
}
