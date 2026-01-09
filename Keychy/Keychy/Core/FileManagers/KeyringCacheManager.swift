//
//  KeyringCacheManager.swift
//  Keychy
//
//  Created by Jini on 1/9/26.
//

import SwiftUI
import SpriteKit

@Observable
class KeyringCacheManager {
    static let shared = KeyringCacheManager()
    
    private init() {
        setupBackgroundObserver()
    }
    
    // MARK: - Properties
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private var failedAttempts: [String: Int] = [:]
    private let maxRetries = 3
    private var backgroundObserver: NSObjectProtocol?
    
    // MARK: - 백그라운드 관찰
    private func setupBackgroundObserver() {
        Task { @MainActor in
            self.backgroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.cancelAllTasks()
                }
            }
        }
    }
    
    // MARK: - Task 관리
    func cancelAllTasks() async {
        for (_, task) in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        print("🔴 모든 캡처 Task 취소됨 (\(activeTasks.count)개)")
    }
    
    func cancelTask(for keyringID: String) {
        activeTasks[keyringID]?.cancel()
        activeTasks.removeValue(forKey: keyringID)
    }
    
    // MARK: - 캡처 요청
    func requestCapture(keyring: Keyring) async {
        guard let keyringID = keyring.documentId else { return }
        
        // 이미 캡처 중이면 무시
        if activeTasks[keyringID] != nil { return }
        
        // 실패 횟수 확인
        let attempts = failedAttempts[keyringID] ?? 0
        if attempts >= maxRetries {
            print("⚠️ 최대 재시도 초과: \(keyringID)")
            return
        }
        
        let task = Task.detached(priority: .utility) {
            await self.captureAndCache(keyring: keyring)
        }
        
        activeTasks[keyringID] = task
    }
    
    // MARK: - 캡처 실행
    private func captureAndCache(keyring: Keyring) async {
        guard let keyringID = keyring.documentId else { return }
        
        defer {
            Task { @MainActor in
                self.activeTasks.removeValue(forKey: keyringID)
            }
        }
        
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)
        
        await withCheckedContinuation { continuation in
            var loadingCompleted = false
            
            let scene = KeyringCellScene(
                ringType: ringType,
                chainType: chainType,
                bodyImage: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
                targetSize: CGSize(width: 175, height: 233),
                customBackgroundColor: .clear,
                zoomScale: 2.0,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.scaleMode = .aspectFill
            
            let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
            view.allowsTransparency = true
            view.presentScene(scene)
            
            Task {
                var waitTime = 0.0
                let checkInterval = 0.15
                let maxWaitTime = 3.0
                
                while !loadingCompleted && waitTime < maxWaitTime {
                    if Task.isCancelled {
                        await self.cleanupScene(scene: scene, view: view)
                        continuation.resume()
                        return
                    }
                    
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                    waitTime += checkInterval
                }
                
                if !loadingCompleted {
                    print("❌ [Cache] 타임아웃: \(keyringID)")
                    await self.recordFailure(keyringID: keyringID)
                    await self.cleanupScene(scene: scene, view: view)
                    continuation.resume()
                    return
                }
                
                if Task.isCancelled {
                    await self.cleanupScene(scene: scene, view: view)
                    continuation.resume()
                    return
                }
                
                try? await Task.sleep(for: .seconds(0.15))
                
                guard !Task.isCancelled else {
                    await self.cleanupScene(scene: scene, view: view)
                    continuation.resume()
                    return
                }
                
                if let pngData = await scene.captureToPNG(),
                   !pngData.isEmpty,
                   let image = UIImage(data: pngData),
                   image.size.width > 0,
                   image.size.height > 0,
                   !ImageValidator.isBlankImage(image) {
                    
                    guard !Task.isCancelled else {
                        await self.cleanupScene(scene: scene, view: view)
                        continuation.resume()
                        return
                    }
                    
                    KeyringImageCache.shared.save(pngData: pngData, for: keyringID, type: .thumbnail)
                    
                    if !keyring.isPackaged && !keyring.isPublished {
                        KeyringImageCache.shared.syncKeyring(
                            id: keyringID,
                            name: keyring.name,
                            imageData: pngData
                        )
                    }
                    
                    await self.clearFailureRecord(keyringID: keyringID)
                    print("✅ [Cache] 성공: \(keyring.name)")
                } else {
                    print("❌ [Cache] 빈 이미지: \(keyringID)")
                    await self.recordFailure(keyringID: keyringID)
                }
                
                await self.cleanupScene(scene: scene, view: view)
                continuation.resume()
            }
        }
    }
    
    // MARK: - Scene Cleanup
    private func cleanupScene(scene: KeyringCellScene, view: SKView) async {
        await MainActor.run {
            scene.removeAllChildren()
            scene.removeAllActions()
            scene.physicsWorld.removeAllJoints()
            view.presentScene(nil)
        }
    }
    
    // MARK: - 실패 기록
    private func recordFailure(keyringID: String) async {
        failedAttempts[keyringID, default: 0] += 1
    }
    
    private func clearFailureRecord(keyringID: String) async {
        failedAttempts.removeValue(forKey: keyringID)
    }
    
    // MARK: - 포그라운드 복귀 재시도
    func retryFailedCaches(keyrings: [Keyring]) async {
        let uncachedKeyrings = keyrings.filter { keyring in
            guard let id = keyring.documentId else { return false }
            
            if (failedAttempts[id] ?? 0) >= maxRetries {
                return false
            }
            
            if !KeyringImageCache.shared.exists(for: id, type: .thumbnail) {
                return true
            }
            
            if let data = KeyringImageCache.shared.load(for: id, type: .thumbnail),
               let image = UIImage(data: data),
               ImageValidator.isBlankImage(image) {
                KeyringImageCache.shared.delete(for: id, type: .thumbnail)
                return true
            }
            
            return false
        }
        
        print("포그라운드 복귀 - 재캡처 대상: \(uncachedKeyrings.count)개")
        
        for keyring in uncachedKeyrings {
            await requestCapture(keyring: keyring)
        }
    }
}

// MARK: - 이미지 유효성 검증
enum ImageValidator {
    static func isBlankImage(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return true
        }
        
        let length = CFDataGetLength(data)
        let sampleCount = min(10, length / 4)
        var nonZeroCount = 0
        
        for i in 0..<sampleCount {
            let offset = (i * length / sampleCount)
            if offset + 3 < length {
                let r = bytes[offset]
                let g = bytes[offset + 1]
                let b = bytes[offset + 2]
                let a = bytes[offset + 3]
                
                if a > 10 && (r > 10 || g > 10 || b > 10) {
                    nonZeroCount += 1
                }
            }
        }
        
        return Double(nonZeroCount) / Double(sampleCount) < 0.3
    }
}
