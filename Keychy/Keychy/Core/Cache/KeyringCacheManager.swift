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
    private var foregroundObserver: NSObjectProtocol?
    
    // 백그라운드 진입 시간 기록
    private var backgroundEntryTime: [String: Date] = [:]
    
    // MARK: - 백그라운드/포그라운드 관찰
    private func setupBackgroundObserver() {
        Task { @MainActor in
            // 백그라운드 진입
            self.backgroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleBackgroundEntry()
                }
            }
            
            // 포그라운드 복귀
            self.foregroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleForegroundReturn()
                }
            }
        }
    }
    
    // 백그라운드 진입 처리
    private func handleBackgroundEntry() async {
        let currentTime = Date()
        
        // 진행 중인 Task 기록 후 취소
        for (keyringID, _) in activeTasks {
            backgroundEntryTime[keyringID] = currentTime
        }
        
        await cancelAllTasks()
        print("백그라운드 진입 - 모든 Task 취소")
    }
    
    // 포그라운드 복귀 처리
    private func handleForegroundReturn() async {
        // 백그라운드에서 취소된 Task들 재시작
        let canceledKeys = Array(backgroundEntryTime.keys)
        backgroundEntryTime.removeAll()
        
        print("포그라운드 복귀 - 취소된 \(canceledKeys.count)개 Task 재시작")
        
        // 재시도 (실패 카운트 초기화하지 않음 - 이미 실패한 것은 제외)
        for keyringID in canceledKeys {
            let attempts = failedAttempts[keyringID] ?? 0
            if attempts < maxRetries {
                print("재시작: \(keyringID)")
            }
        }
    }
    
    // MARK: - Task 관리
    func cancelAllTasks() async {
        for (_, task) in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        print("모든 캡처 Task 취소됨 (\(activeTasks.count)개)")
    }
    
    func cancelTask(for keyringID: String) {
        activeTasks[keyringID]?.cancel()
        activeTasks.removeValue(forKey: keyringID)
    }
    
    // MARK: - 캡처 요청
    func requestCapture(keyring: Keyring) async {
        guard let keyringID = keyring.documentId else { return }
        
        // 1. 유효한 캐시 존재 확인
        if KeyringImageCache.shared.exists(for: keyringID, type: .thumbnail),
           let data = KeyringImageCache.shared.load(for: keyringID, type: .thumbnail),
           let image = UIImage(data: data),
           !ImageValidator.isBlankImage(image) {
            // 유효한 캐시만 스킵
            return
        }
        
        // 2. 유효하지 않은 캐시 삭제
        if KeyringImageCache.shared.exists(for: keyringID, type: .thumbnail) {
            print("유효하지 않은 캐시 삭제: \(keyringID)")
            KeyringImageCache.shared.delete(for: keyringID, type: .thumbnail)
        }
        
        // 3. 이미 캡처 중이면 무시
        if activeTasks[keyringID] != nil { return }
        
        // 4. 실패 횟수 확인
        let attempts = failedAttempts[keyringID] ?? 0
        if attempts >= maxRetries {
            print("최대 재시도 초과: \(keyringID)")
            return
        }
        
        // 5. 캡처 Task 생성
        let task = Task.detached(priority: .utility) {
            await self.captureAndCache(keyring: keyring)
        }
        
        activeTasks[keyringID] = task
    }
    
    // MARK: - 캡처 실행
    private func captureAndCache(keyring: Keyring) async {
        guard let keyringID = keyring.documentId else { return }
        
        defer {
            activeTasks.removeValue(forKey: keyringID)
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
                let maxWaitTime = 5.0
                
                while !loadingCompleted && waitTime < maxWaitTime {
                    if Task.isCancelled {
                        await self.cleanupScene(scene: scene, view: view)
                        continuation.resume()
                        return
                    }
                    
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                    waitTime += checkInterval
                }
                
                if !loadingCompleted || scene.isFallback {
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
                
                // 렌더링 안정화 대기
                try? await Task.sleep(for: .seconds(0.15))
                
                guard !Task.isCancelled else {
                    await self.cleanupScene(scene: scene, view: view)
                    continuation.resume()
                    return
                }
                
                // PNG 캡처
                if let pngData = await scene.captureToPNG(),
                   !pngData.isEmpty,
                   let image = UIImage(data: pngData),
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
                    print("[Cache] 성공: \(keyring.name)")
                } else {
                    print("[Cache] 빈 이미지: \(keyringID)")
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
            // 1. Scene 정리
            scene.removeAllChildren()
            scene.removeAllActions()
            scene.removeFromParent()
            
            // 2. Physics 정리
            scene.physicsWorld.removeAllJoints()
            scene.physicsWorld.speed = 0
            
            // 3. View 정리
            view.presentScene(nil)
            view.removeFromSuperview()
        }
    }
    
    // MARK: - 실패 기록
    private func recordFailure(keyringID: String) async {
        failedAttempts[keyringID, default: 0] += 1
    }
    
    private func clearFailureRecord(keyringID: String) async {
        failedAttempts.removeValue(forKey: keyringID)
    }
    
    // MARK: - 포그라운드 복귀 시 실패 캐시에 대한 재시도
    func retryFailedCaches(keyrings: [Keyring]) async {
        let uncachedKeyrings = keyrings.filter { keyring in
            guard let id = keyring.documentId else {
                return false
            }
            
            // 1. 최대 재시도 초과 체크
            if (failedAttempts[id] ?? 0) >= maxRetries {
                return false
            }
            
            // 2. 캐시 없으면 재시도
            guard KeyringImageCache.shared.exists(for: id, type: .thumbnail) else {
                return true
            }
            
            // 유효성 검증
            guard let data = KeyringImageCache.shared.load(for: id, type: .thumbnail),
                  !data.isEmpty,
                  let image = UIImage(data: data) else {
                KeyringImageCache.shared.delete(for: id, type: .thumbnail)
                return true
            }
            
            // 빈 이미지 감지
            if ImageValidator.isBlankImage(image) {
                KeyringImageCache.shared.delete(for: id, type: .thumbnail)
                return true
            }
            
            return false
        }

        print("포그라운드 복귀 - 재캡처 대상: \(uncachedKeyrings.count)개")

        // 배치 처리
        let batchSize = 5
        for i in stride(from: 0, to: uncachedKeyrings.count, by: batchSize) {
            let batch = Array(uncachedKeyrings[i..<min(i + batchSize, uncachedKeyrings.count)])
            
            await withTaskGroup(of: Void.self) { group in
                for keyring in batch {
                    group.addTask {
                        await self.requestCapture(keyring: keyring)
                    }
                }
            }
            
            // 배치 간 대기 (메모리 안정화)
            try? await Task.sleep(for: .seconds(0.5))
        }
    }
}

// MARK: - 이미지 유효성 검증
enum ImageValidator {
    static func isBlankImage(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else {
            return true
        }
        
        // 1. 이미지 크기 확인 (예상 크기와 비교)
        let width = cgImage.width
        let height = cgImage.height
        
        guard width >= 150, height >= 200 else {
            print("[Validator] 크기 부족: \(width)x\(height)")
            return true
        }
        
        // 2. 픽셀 데이터 검사 (중요)
        guard let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data,
              let bytes = CFDataGetBytePtr(pixelData) else {
            print("[Validator] 픽셀 데이터 없음")
            return true
        }
        
        let length = CFDataGetLength(pixelData)
        let totalPixels = width * height
        
        // 3. 샘플링으로 유효 픽셀 비율 계산
        let sampleCount = min(200, totalPixels / 100)  // 전체의 1% 샘플링
        var nonTransparentCount = 0
        
        for i in 0..<sampleCount {
            let pixelIndex = (i * totalPixels / sampleCount)
            let offset = pixelIndex * 4  // RGBA = 4 bytes
            
            guard offset + 3 < length else { continue }
            
            let r = bytes[offset]
            let g = bytes[offset + 1]
            let b = bytes[offset + 2]
            let a = bytes[offset + 3]
            
            // 알파가 있고, 색상이 있으면 유효 픽셀
            if a > 10 && (r > 10 || g > 10 || b > 10) {
                nonTransparentCount += 1
            }
        }
        
        // 4. 유효 픽셀 비율 계산
        let validRatio = Double(nonTransparentCount) / Double(sampleCount)
        
        // 5% 미만이면 빈 이미지로 판정
        let isBlank = validRatio < 0.05
        
        if isBlank {
            print("[Validator] 빈 이미지: 유효 픽셀 \(String(format: "%.1f%%", validRatio * 100))")
        }
        
        return isBlank
    }
}
