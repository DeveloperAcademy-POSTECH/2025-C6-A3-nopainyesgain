//
//  WorkshopPreview.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI
import Lottie

struct WorkshopPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Environment(UserManager.self) private var userManager
    @State private var effectManager = EffectManager.shared
    @State private var isParticleReady = false

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
        }
        .padding(.horizontal, 30)
        .toolbar(.hidden, for: .tabBar)
        .task {
            // 배경이 무료이고 아직 소유하지 않았다면 자동으로 추가
            if let background = item as? Background {
                await viewModel.addFreeBackgroundIfNeeded(background)
            }
            // 카라비너가 무료이고 아직 소유하지 않았다면 자동으로 추가
            else if let carabiner = item as? Carabiner {
                await viewModel.addFreeCarabinerIfNeeded(carabiner)
            }
        }
    }
}

// MARK: - Item Preview Section
extension WorkshopPreview {
    private var itemPreview: some View {
        GeometryReader { geometry in
            VStack {
                
                Spacer()

                // 파티클이 아닌 경우 이미지 표시
                if !(item is Particle) {
                    ItemDetailImage(itemURL: getPreviewURL())
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(20)
                }

                // 파티클 이펙트일 경우 무한 재생
                if let particle = item as? Particle,
                   let particleId = particle.id {
                    if isParticleReady {
                        infiniteParticleLottieView(particleId: particleId)
                    } else {
                        ProgressView()
                            .task {
                                await ensureParticleReady(particle)
                            }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 30)
            .frame(height: 500)
        }
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
                // TODO: 구매 로직 구현
                print("구매: \(item.name) - \(item.workshopPrice) 코인")
            }
        )
    }
}

#Preview {
    // 프리뷰용 샘플 Sound
    let sampleSound = Sound(
        id: "sample_sound_1",
        soundName: "딸랑딸랑",
        description: "귀여운 종소리 효과음",
        soundData: "sample_bell.mp3",
        thumbnail: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Backgrounds%2FCloudHangerBack.png?alt=media&token=74b8d537-6b27-4562-8536-3b97624e1e9f"
,
        tags: ["귀여움", "종소리"],
        price: 100,
        downloadCount: 42,
        useCount: 123,
        createdAt: Date()
    )
    
    return WorkshopPreview(
        router: NavigationRouter<WorkshopRoute>(),
        viewModel: WorkshopViewModel(userManager: UserManager.shared),
        item: sampleSound
    )
    .environment(UserManager.shared)
}
