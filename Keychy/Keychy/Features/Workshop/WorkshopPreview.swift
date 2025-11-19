//
//  WorkshopPreview.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI
import Lottie
import FirebaseFirestore

struct WorkshopPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Environment(UserManager.self) private var userManager
    @State private var effectManager = EffectManager.shared
    @State private var isParticleReady = false

    // 구매 관련 상태
    @State private var showPurchaseSheet = false
    @State private var purchasePopupScale: CGFloat = 0.3
    @State private var showPurchasingLoading = false
    @State private var showPurchaseSuccessAlert = false
    @State private var showPurchaseFailAlert = false

    let viewModel: WorkshopViewModel
    let item: any WorkshopItem
    
    /// 아이템 보유 여부 확인
    private var isOwned: Bool {
        guard let user = userManager.currentUser,
              let itemId = item.id else { return false }
        
        if item is KeyringTemplate {
            return user.templates.contains(itemId)
        } else if item is Background {
            return user.backgrounds.contains(itemId)
        } else if item is Carabiner {
            return user.carabiners.contains(itemId)
        } else if item is Particle {
            return user.particleEffects.contains(itemId)
        } else if item is Sound {
            return user.soundEffects.contains(itemId)
        }
        return false
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                
                Spacer()
                
                itemPreview
                
                Spacer()
                
                HStack {
                    ItemDetailInfoSection(item: item)
                    
                    Spacer()
                    
                    // 사운드일 경우 재생 버튼 표시
                    if item is Sound {
                        VStack {
                            Spacer()
                            effectPlayButton
                        }
                    }
                }
                .padding(.bottom, 40)
                .frame(height: 120)
                
                actionButton
                    .adaptiveBottomPadding()
                    .padding(.bottom, getBottomPadding(0) != 0 ? 0 : 34)
            }
            .padding(.horizontal, 30)
            
            CustomNavigationBar {
                BackToolbarButton {
                    router.pop()
                }
            } center: {
                Spacer()
            } trailing: {
                Spacer()
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .swipeBackGesture(enabled: true)
        .overlay {
            ZStack(alignment: .center) {
                // 구매 확인 팝업
                if showPurchaseSheet {
                    Color.black20
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                purchasePopupScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showPurchaseSheet = false
                            }
                        }

                    PurchasePopup(
                        title: item.name,
                        myCoin: userManager.currentUser?.coin ?? 0,
                        price: item.workshopPrice,
                        scale: purchasePopupScale,
                        onConfirm: {
                            Task {
                                await handlePurchase()
                            }
                        }
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }

                // 구매 중 로딩
                if showPurchasingLoading {
                    LoadingAlert(type: .short, message: nil)
                }

                // 구매 성공 알림
                if showPurchaseSuccessAlert {
                    KeychyAlert(
                        type: .checkmark,
                        message: "구매가 완료되었어요!",
                        isPresented: $showPurchaseSuccessAlert
                    )
                }

                // 구매 실패 알림 (코인 부족)
                if showPurchaseFailAlert {
                    ZStack {
                        Color.black20
                            .zIndex(99)

                        LackPopup(
                            title: "코인이 부족해요",
                            onCancel: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showPurchaseFailAlert = false
                                }
                            },
                            onConfirm: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showPurchaseFailAlert = false
                                    router.push(.coinCharge)
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }
}

// MARK: - Item Preview Section
extension WorkshopPreview {
    private var itemPreview: some View {
        VStack {
            Spacer()

            // 파티클이 아닌 경우 이미지 표시
            if !(item is Particle) {
                if item is Background {
                    ItemDetailImage(itemURL: getPreviewURL())
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: getBottomPadding(0) == 0 ? 380 : 501)
                        .cornerRadius(20)
                } else {
                    // 카라비너, 사운드: 1:1 비율
                    ItemDetailImage(itemURL: getPreviewURL())
                        .scaledToFit()
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(20)
                }
            }
            
            // 파티클 이펙트일 경우 무한 재생 (1:1 비율)
            if let particle = item as? Particle,
               let particleId = particle.id {
                if isParticleReady {
                    infiniteParticleLottieView(particleId: particleId)
                        .scaledToFill()
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(20)
                } else {
                    LoadingAlert(type: .short, message: nil)
                        .scaleEffect(0.5)
                    .task {
                        await ensureParticleReady(particle)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 30)
        .frame(maxHeight: 500)
    }

    /// 파티클 다운로드 및 소유권 처리
    private func ensureParticleReady(_ particle: Particle) async {
        guard let particleId = particle.id else { return }

        // 무료 파티클이고 아직 소유하지 않았다면 소유권 추가
        if particle.isFree && !(userManager.currentUser?.particleEffects.contains(particleId) ?? false) {
            // playParticle을 통해 다운로드 및 소유권 처리
            await effectManager.playParticle(particle, userManager: userManager)
        } else {
            // 이미 캐시 또는 Bundle에 있으면 바로 준비 완료
            if effectManager.isInCache(particleId: particleId) || effectManager.isInBundle(particleId: particleId) {
                isParticleReady = true
                return
            }

            // 다운로드 필요
            await effectManager.downloadParticle(particle, userManager: userManager)
        }

        isParticleReady = true
    }

    /// 파티클 무한 재생 뷰
    private func infiniteParticleLottieView(particleId: String) -> some View {
        LottieView(
            name: particleId,
            loopMode: .loop,  // 무한 재생
            speed: 1.0
        )
    }
    
    /// 사운드 재생 버튼
    private var effectPlayButton: some View {
        let itemId = item.id ?? ""
        let isDownloading = effectManager.downloadingItemIds.contains(itemId)
        let progress = effectManager.downloadProgress[itemId] ?? 0.0

        return Button {
            Task {
                if let sound = item as? Sound {
                    await effectManager.playSound(sound, userManager: userManager)
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.black100)
                    .frame(width: 38, height: 38)

                if isDownloading {
                    CircularProgressView(progress: progress)
                        .frame(width: 20, height: 20)
                } else {
                    Image(.whitePolygon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                }
            }
        }
        .disabled(isDownloading)
    }
    
    /// 프리뷰 이미지 URL 가져오기
    private func getPreviewURL() -> String {
        if let template = item as? KeyringTemplate {
            return template.previewURL
        } else if let background = item as? Background {
            return background.backgroundImage
        } else if let carabiner = item as? Carabiner {
            return carabiner.carabinerImage[0]
        } else if let particle = item as? Particle {
            return particle.thumbnail
        } else if let sound = item as? Sound {
            return sound.thumbnail
        }
        return item.thumbnailURL
    }
}

// MARK: - Action Button Section
extension WorkshopPreview {
    private var actionButton: some View {
        WorkshopItemActionButton(
            item: item,
            isOwned: isOwned,
            onPurchase: {
                showPurchaseSheet = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    purchasePopupScale = 1.0
                }
            }
        )
    }

    /// 구매 처리
    private func handlePurchase() async {
        // 팝업 닫기 애니메이션
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                purchasePopupScale = 0.3
            }
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        await MainActor.run {
            showPurchaseSheet = false
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        // 로딩 시작
        await MainActor.run {
            showPurchasingLoading = true
        }

        // ItemPurchaseManager를 통해 구매 처리
        let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(item, userManager: userManager)

        // 로딩 종료
        await MainActor.run {
            showPurchasingLoading = false
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        switch result {
        case .success:
            // 성공 시 성공 알림 표시
            showPurchaseSuccessAlert = true

        case .insufficientCoins:
            // 코인 부족 시 실패 알림 표시
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showPurchaseFailAlert = true
                }
            }

        case .failed(let message):
            // 기타 실패 시 에러 출력
            print("구매 실패: \(message)")
        }
    }
}
