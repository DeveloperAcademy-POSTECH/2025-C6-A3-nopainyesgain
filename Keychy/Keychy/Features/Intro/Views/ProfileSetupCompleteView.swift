//
//  ProfileSetupCompleteView.swift
//  Keychy
//
//  Created by Jini on 10/31/25.
//

import SwiftUI
import Lottie

struct ProfileSetupCompleteView: View {
    @Bindable var viewModel: IntroViewModel
    @State private var keyringViewModel: WelcomeKeyringViewModel? = nil
    @State private var isSaving: Bool = false
    @State private var isLoadingResources: Bool = true
    @State private var isSceneReady: Bool = false
    @State private var showNextButton: Bool = false
    @State private var loadingScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            keyring
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 30)
                .blur(radius: isSaving ? 15 : 0)

            VStack(spacing: 0) {
                title
                    .padding(.horizontal, 34)

                Spacer()

                nextBtn
                    .padding(.horizontal, 34)
            }
            .disabled(isLoadingResources || !isSceneReady || isSaving)
            .blur(radius: isSaving ? 15 : 0)

            if isSaving {
                LoadingAlert(type: .short, message: nil)
            }
        }
        .background(.white100)
        .onAppear {
            setupKeyringViewModel()
        }
        .task {
            await preloadResources()
        }
    }
}

// MARK: - Lifecycle & Actions
extension ProfileSetupCompleteView {

    private func setupKeyringViewModel() {
        guard let bodyImage = UIImage.createWelcomeBody(nickname: viewModel.welcomeNickname) else {
            return
        }

        keyringViewModel = WelcomeKeyringViewModel(
            nickname: viewModel.welcomeNickname,
            bodyImage: bodyImage
        )
    }

    private func preloadResources() async {
        await preloadConfettiParticle()
        isLoadingResources = false
        closeLoadingIfReady()
    }

    private func preloadConfettiParticle() async {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let cachedURL = cacheDirectory.appendingPathComponent("particles/Confetti.json")

                if FileManager.default.fileExists(atPath: cachedURL.path) {
                    _ = LottieAnimation.filepath(cachedURL.path)
                } else {
                    _ = LottieAnimation.named("Confetti")
                }

                continuation.resume()
            }
        }
    }

    private func closeLoadingIfReady() {
        if !isLoadingResources && isSceneReady {
            withAnimation {
                // 조건 만족 시 자동으로 UI 업데이트됨
            }
        }
    }

    private func saveWelcomeKeyring() {
        guard let bodyImage = keyringViewModel?.bodyImage else {
            viewModel.completeOnboarding()
            return
        }

        isSaving = true

        Task {
            // 1. User 프로필을 Firestore에 저장
            let profileSaved = await withCheckedContinuation { continuation in
                viewModel.saveProfileToFirestore { success in
                    continuation.resume(returning: success)
                }
            }

            guard profileSaved,
                  let uid = UserManager.shared.currentUser?.id else {
                await MainActor.run {
                    isSaving = false
                    viewModel.completeOnboarding()
                }
                return
            }

            // 2. 환영 키링 저장
            do {
                let keyringId = try await viewModel.createWelcomeKeyring(
                    nickname: viewModel.welcomeNickname,
                    bodyImage: bodyImage,
                    uid: uid
                )

                // 3. 웰컴 뭉치 생성
                let bundleCreated = await withCheckedContinuation { continuation in
                    viewModel.makeBundle(welcomeKeyringId: keyringId) { success, _ in
                        continuation.resume(returning: success)
                    }
                }

                if !bundleCreated {
                    print("이미 만들어졌음")
                }

                await MainActor.run {
                    isSaving = false
                    viewModel.completeOnboarding()
                }
            } catch {
                print("웰컴 키링 생성 실패: \(error)")
                await MainActor.run {
                    isSaving = false
                    viewModel.completeOnboarding()
                }
            }
        }
    }
}

// MARK: - UI Components
extension ProfileSetupCompleteView {

    private var title: some View {
        Text("환영합니다!\n가입 환영 키링이 완성되었어요!")
            .typography(.suit24B)
            .foregroundStyle(.black100)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.top, 54)
            .opacity(isSceneReady ? 1.0 : 0.0)
            .scaleEffect(isSceneReady ? 1.0 : 0.9)
    }

    private var keyring: some View {
        ZStack {
            if let keyringViewModel {
                KeyringSceneView(
                    viewModel: keyringViewModel,
                    backgroundColor: .clear,
                    applyWelcomeImpulse: true,  // 자동 파티클 효과!
                    onSceneReady: {
                        // 1초 딜레이 후 키링 표시
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeIn(duration: 1.0)) {
                                isSceneReady = true
                            }
                            closeLoadingIfReady()

                            // 다음 버튼 애니메이션 등장
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    showNextButton = true
                                }
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .opacity(isSceneReady ? 1.0 : 0.0)
            }

            if isLoadingResources || !isSceneReady {
                LoadingAlert(type: .longWithKeychy, message: "환영 키링을 만드는 중이에요!")
            }
        }
    }

    private var nextBtn: some View {
        Button {
            saveWelcomeKeyring()
        } label: {
            Text("다음")
                .typography(.suit17B)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
        }
        .buttonStyle(.glassProminent)
        .tint(.main500)
        .foregroundStyle(.white100)
        .disabled(isSaving || isLoadingResources || !isSceneReady)
        .opacity(showNextButton ? 1 : 0)
        .scaleEffect(showNextButton ? 1 : 0.3)
    }
}

#Preview {
    ProfileSetupCompleteView(viewModel: IntroViewModel())
}
