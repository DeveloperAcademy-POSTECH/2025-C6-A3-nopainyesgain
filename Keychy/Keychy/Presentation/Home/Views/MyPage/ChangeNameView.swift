//
//  ChangeNameView.swift
//  Keychy
//
//  Created by 길지훈 on 11/6/25.
//

import SwiftUI
import FirebaseFirestore

// 닉네임 변경 뷰
struct ChangeNameView: View {
    @Environment(UserManager.self) private var userManager
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var toastManager = ToastManager.shared

    @State private var viewModel = ChangeNameViewModel()

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            mainContent
            alerts
            toastOverlay
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .toolbar {
            backToolbarItem
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("닉네임 변경")
        .tint(.black)
        .dismissKeyboardOnTap()
        .swipeBackGesture(enabled: true)
        .onAppear {
            TabBarManager.hide()
            viewModel.initialize(currentNickname: userManager.currentUser?.nickname ?? "")
        }
    }
}

// MARK: - UI Components
extension ChangeNameView {
    /// 메인 컨텐츠
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            nicknameInputSection
                .padding(.top, 22)

            Spacer()

            submitButton
        }
        .padding(.horizontal, 20)
        .blur(radius: (viewModel.showSuccessAlert || viewModel.isUpdating) ? 10 : 0)
        .animation(.easeInOut(duration: 0.3), value: (viewModel.showSuccessAlert || viewModel.isUpdating))
    }

    /// 토스트 오버레이
    @ViewBuilder
    private var toastOverlay: some View {
        if toastManager.showToast {
            VStack {
                Spacer()
                NoInternetToast()
                    .padding(.bottom, 104)
                    .opacity(toastManager.opacity)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    /// 닉네임 입력 섹션
    private var nicknameInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("닉네임")
                .typography(.suit16B)

            HStack {
                nicknameTextField

                // 글자수 표시 또는 로딩
                if viewModel.isCheckingDuplicate {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("\(viewModel.nickname.count)/\(viewModel.maxNicknameLength)")
                        .typography(.suit13M)
                        .foregroundColor(.gray300)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray50)
            )

            validationMessageText
        }
    }

    /// 닉네임 입력 필드
    private var nicknameTextField: some View {
        TextField("닉네임을 적어주세요.", text: $viewModel.nickname)
            .typography(.notosans15M)
            .textFieldStyle(.plain)
            .tint(.main500)
            .onChange(of: viewModel.nickname) { oldValue, newValue in
                handleNicknameChange(newValue)
            }
    }

    /// 유효성 검사 메시지
    private var validationMessageText: some View {
        Text(viewModel.validationMessage)
            .typography(.suit14M)
            .foregroundColor(
                viewModel.isValidationPositive ? .gray400 :
                    (viewModel.validationMessage == "영문, 숫자, 한글만 입력 가능해요." ? .gray400 : .red)
            )
    }

    /// 변경 버튼
    private var submitButton: some View {
        Button {
            if viewModel.isNicknameValid {
                handleUpdateNickname()
            }
        } label: {
            Text("변경")
                .typography(.suit17B)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(viewModel.isNicknameValid ? .main500 : .black20)
        .foregroundStyle(viewModel.isNicknameValid ? .white100 : .black40)
        .disabled(!viewModel.isNicknameValid)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isNicknameValid)
        .padding(.bottom, 34)
    }

    /// Alert들
    private var alerts: some View {
        Group {
            // 업데이트 중 로딩
            if viewModel.isUpdating {
                LoadingAlert(type: .short, message: nil)
            }

            // 성공 Alert
            if viewModel.showSuccessAlert {
                KeychyAlert(
                    type: .checkmark,
                    message: "닉네임이 변경되었습니다.",
                    isPresented: $viewModel.showSuccessAlert
                )
            }
        }
    }

    /// Toolbar Items
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
            .frame(width: 32, height: 32)
            .opacity(viewModel.showSuccessAlert || viewModel.isUpdating ? 0 : 1)
            .allowsHitTesting(!viewModel.showSuccessAlert && !viewModel.isUpdating)
        }
        .sharedBackgroundVisibility(viewModel.showSuccessAlert || viewModel.isUpdating ? .hidden : .visible)
    }
}

// MARK: - Actions
extension ChangeNameView {
    /// 닉네임 입력 변경 처리
    private func handleNicknameChange(_ newValue: String) {
        // 글자수 제한
        if newValue.count > viewModel.maxNicknameLength {
            viewModel.nickname = String(newValue.prefix(viewModel.maxNicknameLength))
        }

        // 기존 검사 Task 취소
        viewModel.validationTask?.cancel()

        // 입력 중일 때는 기본 메시지
        if !newValue.isEmpty {
            viewModel.validationMessage = "영문, 숫자, 한글만 입력 가능해요."
            viewModel.isValidationPositive = false
        } else {
            viewModel.validationMessage = "영문, 숫자, 한글만 입력 가능해요."
            viewModel.isValidationPositive = false
        }

        // 0.5초 후 유효성 검사
        viewModel.validationTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            if !Task.isCancelled {
                await MainActor.run {
                    viewModel.validateNickname(newValue)
                }
            }
        }
    }

    /// 닉네임 업데이트 처리
    private func handleUpdateNickname() {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            ToastManager.shared.show()
            return
        }

        guard let currentUser = userManager.currentUser else { return }

        viewModel.updateNickname(
            userId: currentUser.id,
            currentNickname: currentUser.nickname
        ) { success in
            if success {
                // UserManager 업데이트
                userManager.loadUserInfo(uid: currentUser.id) { _ in }

                // 2초 후 뒤로가기 (KeychyAlert duration이 2초)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                    router.pop()
                }
            }
        }
    }
}
