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

    // MARK: - Profanity Filtering
    @State var validationMessage: String = ""
    @State var hasProfanity: Bool = false

    // MARK: - Firebase Saving States
    @State var isSavingToFirebase: Bool = false

    // Firebase
    let db = Firestore.firestore()

    // MARK: - Dynamic Sheet Heights
    /// 고정된 detents (태그 줄 수에 따라 단계별로)
    private var dynamicDetents: Set<PresentationDetent> {
        [
            .height(76),   // 접힌 상태
            .height(395),  // 1줄
            .height(440),  // 2줄
            .height(485),  // 3줄
            .height(530),  // 4줄
            .height(575),  // 5줄
            .height(620)   // 6줄
        ]
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            ZStack {
                Color.gray50
                    .ignoresSafeArea()

                keyringScene
                    .frame(maxWidth: .infinity)
            }
            .blur(radius: isSavingToFirebase ? 15 : 0)
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .interactiveDismissDisabled(true)
            .sheet(isPresented: $showSheet) {
                infoSheet
                    .presentationDetents(
                        showAddTagAlert
                            ? [.height(76)]
                            : dynamicDetents,
                        selection: $sheetDetent
                    )
                    .presentationDragIndicator(showAddTagAlert ? .hidden : .visible)
                    .presentationBackgroundInteraction(
                        showAddTagAlert
                            ? .enabled
                            : .enabled(upThrough: .height(measuredSheetHeight))
                    )
                    .interactiveDismissDisabled()
                    .onAppear {
                        sheetDetent = .height(measuredSheetHeight)
                    }
                    .onChange(of: measuredSheetHeight) { _, newHeight in
                        // 측정된 높이가 변경되면 자동으로 이동
                        if sheetDetent != .height(76) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                sheetDetent = .height(newHeight)
                            }
                        }
                    }
            }
            .blur(radius: isSavingToFirebase ? 15 : 0)
            .dismissKeyboardOnTap()

            // Alert overlay
            if showAddTagAlert {
                Color.black60
                    .ignoresSafeArea()
                    .zIndex(99)

                addNewTagAlertView
                    .padding(.horizontal, 51)
                    .zIndex(100)
            }

            // Firebase 저장 중 로딩
            if isSavingToFirebase {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .zIndex(98)

                LoadingAlert(type: .longWithKeychy, message: "키링을 만드는 중이에요!")
                    .zIndex(99)
            }

            // 커스텀 네비게이션 바
            customNavigationBar
                .blur(radius: isSavingToFirebase ? 15 : 0)
                .zIndex(0)
        }
        .ignoresSafeArea()
    }
}
