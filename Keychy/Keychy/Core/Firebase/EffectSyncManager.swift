//
//  EffectSyncManager.swift
//  Keychy
//
//  이펙트 동기화 매니저
//  - 로그인 시 구매한 이펙트 동기화
//  - 선물 수령 시 키링의 이펙트 동기화
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

@Observable
class EffectSyncManager {
    static let shared = EffectSyncManager()

    private init() {}

    // MARK: - 로그인 시 구매한 이펙트 동기화
    /// 사용자가 구매한 모든 이펙트 + 키링에 사용된 모든 이펙트를 캐시에 다운로드
    func syncPurchasedEffects(userId: String) async {
        print("[EffectSync] 이펙트 동기화 시작: \(userId)")

        // 1. 구매한 이펙트 동기화 (유료)
        async let purchasedTask: () = {
            async let soundsTask: () = self.syncPurchasedSounds(userId: userId)
            async let particlesTask: () = self.syncPurchasedParticles(userId: userId)
            await soundsTask
            await particlesTask
        }()

        // 2. 키링에 사용된 이펙트 동기화 (유료 + 무료)
        async let keyringsTask: () = syncKeyringEffectsFromUser(userId: userId)

        await purchasedTask
        await keyringsTask

        print("[EffectSync] 이펙트 동기화 완료")
    }

    // MARK: - 유저의 모든 키링에서 사용된 이펙트 동기화
    /// 유저가 가진 모든 키링의 이펙트를 캐시에 다운로드
    private func syncKeyringEffectsFromUser(userId: String) async {
        do {
            // User 문서에서 keyrings 배열 가져오기
            let userSnapshot = try await Firestore.firestore()
                .collection("User")
                .document(userId)
                .getDocument()

            guard let userData = userSnapshot.data(),
                  let keyringIds = userData["keyrings"] as? [String] else {
                print("[EffectSync] keyrings 필드 없음")
                return
            }

            print("[EffectSync] 유저의 키링 개수: \(keyringIds.count)")

            // 모든 키링 문서 조회
            let keyringSnapshots = try await withThrowingTaskGroup(of: DocumentSnapshot?.self) { group in
                for keyringId in keyringIds {
                    group.addTask {
                        try? await Firestore.firestore()
                            .collection("Keyring")
                            .document(keyringId)
                            .getDocument()
                    }
                }

                var snapshots: [DocumentSnapshot] = []
                for try await snapshot in group {
                    if let snapshot = snapshot, snapshot.exists {
                        snapshots.append(snapshot)
                    }
                }
                return snapshots
            }

            // 각 키링에서 soundId, particleId 추출
            var soundIds = Set<String>()
            var particleIds = Set<String>()

            for snapshot in keyringSnapshots {
                if let data = snapshot.data() {
                    if let soundId = data["soundId"] as? String,
                       !soundId.isEmpty,
                       soundId != "none",
                       soundId != "custom_recording" {
                        soundIds.insert(soundId)
                    }
                    if let particleId = data["particleId"] as? String,
                       !particleId.isEmpty,
                       particleId != "none" {
                        particleIds.insert(particleId)
                    }
                }
            }

            print("[EffectSync] 키링에서 발견된 사운드: \(soundIds.count)개")
            print("[EffectSync] 키링에서 발견된 파티클: \(particleIds.count)개")

            // 병렬 다운로드 (downloadIfNeeded 함수 내부에서 체크함)
            await withTaskGroup(of: Void.self) { group in
                // 사운드 다운로드
                for soundId in soundIds {
                    group.addTask {
                        await self.downloadSoundIfNeeded(soundId: soundId)
                    }
                }

                // 파티클 다운로드
                for particleId in particleIds {
                    group.addTask {
                        await self.downloadParticleIfNeeded(particleId: particleId)
                    }
                }
            }

        } catch {
            print("[EffectSync] 키링 이펙트 동기화 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 선물 수령 시 키링 이펙트 동기화
    /// 선물받은 키링의 이펙트를 캐시에 다운로드 (없는 경우에만)
    func syncKeyringEffects(soundId: String?, particleId: String?) async {
        print("[EffectSync] 키링 이펙트 동기화 시작")

        async let soundTask: () = {
            if let soundId = soundId,
               !soundId.isEmpty,
               soundId != "none",
               soundId != "custom_recording" {
                await self.downloadSoundIfNeeded(soundId: soundId)
            }
        }()

        async let particleTask: () = {
            if let particleId = particleId,
               !particleId.isEmpty,
               particleId != "none" {
                await self.downloadParticleIfNeeded(particleId: particleId)
            }
        }()

        await soundTask
        await particleTask

        print("[EffectSync] 키링 이펙트 동기화 완료")
    }

    // MARK: - Private Helpers

    /// 구매한 사운드 동기화
    private func syncPurchasedSounds(userId: String) async {
        do {
            // User 문서에서 soundEffects 배열 가져오기
            let snapshot = try await Firestore.firestore()
                .collection("User")
                .document(userId)
                .getDocument()

            guard let data = snapshot.data(),
                  let soundEffects = data["soundEffects"] as? [String] else {
                print("[EffectSync] soundEffects 필드 없음")
                return
            }

            print("[EffectSync] 구매한 사운드: \(soundEffects.count)개")

            // 병렬 다운로드
            await withTaskGroup(of: Void.self) { group in
                for soundId in soundEffects {
                    // 캐시에 없으면 다운로드
                    if !isInCache(soundId: soundId) {
                        group.addTask {
                            await self.downloadSoundIfNeeded(soundId: soundId)
                        }
                    }
                }
            }
        } catch {
            print("[EffectSync] 구매한 사운드 조회 실패: \(error.localizedDescription)")
        }
    }

    /// 구매한 파티클 동기화
    private func syncPurchasedParticles(userId: String) async {
        do {
            // User 문서에서 particleEffects 배열 가져오기
            let snapshot = try await Firestore.firestore()
                .collection("User")
                .document(userId)
                .getDocument()

            guard let data = snapshot.data(),
                  let particleEffects = data["particleEffects"] as? [String] else {
                print("[EffectSync] particleEffects 필드 없음")
                return
            }

            print("[EffectSync] 구매한 파티클: \(particleEffects.count)개")

            // 병렬 다운로드
            await withTaskGroup(of: Void.self) { group in
                for particleId in particleEffects {
                    // 캐시에 없으면 다운로드
                    if !isInCache(particleId: particleId) {
                        group.addTask {
                            await self.downloadParticleIfNeeded(particleId: particleId)
                        }
                    }
                }
            }
        } catch {
            print("[EffectSync] 구매한 파티클 조회 실패: \(error.localizedDescription)")
        }
    }

    /// 사운드 다운로드 (캐시에 없을 때만)
    private func downloadSoundIfNeeded(soundId: String) async {
        // 번들에 있으면 스킵 (무료 이펙트)
        if isInBundle(soundId: soundId) {
            print("[EffectSync] 사운드 번들에 있음 (스킵): \(soundId)")
            return
        }

        // 캐시에 있으면 스킵
        guard !isInCache(soundId: soundId) else {
            print("[EffectSync] 사운드 이미 캐시에 있음: \(soundId)")
            return
        }

        do {
            // Firestore에서 soundData URL 가져오기
            let soundSnapshot = try await Firestore.firestore()
                .collection("Sound")
                .document(soundId)
                .getDocument()

            guard let soundData = soundSnapshot.data(),
                  let soundURL = soundData["soundData"] as? String else {
                print("[EffectSync] soundData URL 없음: \(soundId)")
                return
            }

            // Storage URL로 참조 생성
            let storageRef = Storage.storage().reference(forURL: soundURL)

            let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let soundsDir = cacheDirectory.appendingPathComponent("sounds")

            // 디렉토리 생성
            if !FileManager.default.fileExists(atPath: soundsDir.path) {
                try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            }

            let localURL = soundsDir.appendingPathComponent("\(soundId).mp3")

            // 다운로드
            _ = try await storageRef.write(toFile: localURL)
            print("[EffectSync] 사운드 다운로드 완료: \(soundId)")

        } catch {
            print("[EffectSync] 사운드 다운로드 실패 (\(soundId)): \(error.localizedDescription)")
        }
    }

    /// 파티클 다운로드 (캐시에 없을 때만)
    private func downloadParticleIfNeeded(particleId: String) async {
        // 번들에 있으면 스킵 (무료 이펙트)
        if isInBundle(particleId: particleId) {
            print("[EffectSync] 파티클 번들에 있음 (스킵): \(particleId)")
            return
        }

        // 캐시에 있으면 스킵
        guard !isInCache(particleId: particleId) else {
            print("[EffectSync] 파티클 이미 캐시에 있음: \(particleId)")
            return
        }

        do {
            // Firestore에서 particleData URL 가져오기
            let particleSnapshot = try await Firestore.firestore()
                .collection("Particle")
                .document(particleId)
                .getDocument()

            guard let particleData = particleSnapshot.data(),
                  let particleURL = particleData["particleData"] as? String else {
                print("[EffectSync] particleData URL 없음: \(particleId)")
                return
            }

            // Storage URL로 참조 생성
            let storageRef = Storage.storage().reference(forURL: particleURL)

            let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let particlesDir = cacheDirectory.appendingPathComponent("particles")

            // 디렉토리 생성
            if !FileManager.default.fileExists(atPath: particlesDir.path) {
                try FileManager.default.createDirectory(at: particlesDir, withIntermediateDirectories: true)
            }

            let localURL = particlesDir.appendingPathComponent("\(particleId).json")

            // 다운로드
            _ = try await storageRef.write(toFile: localURL)
            print("[EffectSync] 파티클 다운로드 완료: \(particleId)")

        } catch {
            print("[EffectSync] 파티클 다운로드 실패 (\(particleId)): \(error.localizedDescription)")
        }
    }

    // MARK: - Cache & Bundle Check

    /// 사운드가 캐시에 있는지 확인
    private func isInCache(soundId: String) -> Bool {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("sounds/\(soundId).mp3")
        return FileManager.default.fileExists(atPath: cachedURL.path)
    }

    /// 파티클이 캐시에 있는지 확인
    private func isInCache(particleId: String) -> Bool {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cachedURL = cacheDirectory.appendingPathComponent("particles/\(particleId).json")
        return FileManager.default.fileExists(atPath: cachedURL.path)
    }

    /// 사운드가 번들에 있는지 확인 (무료 이펙트)
    private func isInBundle(soundId: String) -> Bool {
        return Bundle.main.path(forResource: soundId, ofType: "mp3") != nil
    }

    /// 파티클이 번들에 있는지 확인 (무료 이펙트)
    private func isInBundle(particleId: String) -> Bool {
        return Bundle.main.path(forResource: particleId, ofType: "json") != nil
    }
}
