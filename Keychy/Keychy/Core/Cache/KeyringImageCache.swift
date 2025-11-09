//
//  KeyringImageCache.swift
//  Keychy
//
//  Created by Claude on 11/9/25.
//

import Foundation
import SwiftUI
#if targetEnvironment(simulator)
import AppKit
#endif

/// Keyring 썸네일 이미지를 FileManager 기반으로 캐싱
class KeyringImageCache {
    static let shared = KeyringImageCache()

    private let fileManager = FileManager.default

    /// 캐시 디렉토리 경로
    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let keyringCache = urls[0].appendingPathComponent("KeyringThumbnails", isDirectory: true)

        // 디렉토리가 없으면 생성
        if !fileManager.fileExists(atPath: keyringCache.path) {
            do {
                try fileManager.createDirectory(at: keyringCache, withIntermediateDirectories: true)
                print("✅ [KeyringCache] 캐시 디렉토리 생성 완료: \(keyringCache.path)")
            } catch {
                print("❌ [KeyringCache] 캐시 디렉토리 생성 실패: \(error.localizedDescription)")
            }
        }

        return keyringCache
    }

    private init() {
        print("📁 [KeyringCache] 초기화 완료")
        print("📁 [KeyringCache] 캐시 경로: \(cacheDirectory.path)")
    }

    // MARK: - 저장

    /// PNG 데이터를 파일로 저장
    func save(pngData: Data, for keyringID: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(keyringID).png")

        do {
            try pngData.write(to: fileURL)
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(pngData.count), countStyle: .file)
            print("💾 [KeyringCache] 저장 완료: \(keyringID) (\(fileSize))")
        } catch {
            print("❌ [KeyringCache] 저장 실패: \(keyringID) - \(error.localizedDescription)")
        }
    }

    // MARK: - 불러오기

    /// 캐시된 PNG 데이터 로드
    func load(for keyringID: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent("\(keyringID).png")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("📭 [KeyringCache] 캐시 없음: \(keyringID)")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
            print("📂 [KeyringCache] 로드 완료: \(keyringID) (\(fileSize))")
            return data
        } catch {
            print("❌ [KeyringCache] 로드 실패: \(keyringID) - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 삭제

    /// 특정 키링 캐시 삭제
    func delete(for keyringID: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(keyringID).png")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("📭 [KeyringCache] 삭제할 파일 없음: \(keyringID)")
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
            print("🗑️ [KeyringCache] 삭제 완료: \(keyringID)")
        } catch {
            print("❌ [KeyringCache] 삭제 실패: \(keyringID) - \(error.localizedDescription)")
        }
    }

    // MARK: - 전체 캐시 삭제

    /// 모든 캐시 파일 삭제
    func clearAll() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)

            for file in files where file.pathExtension == "png" {
                try fileManager.removeItem(at: file)
            }

            print("🗑️ [KeyringCache] 전체 캐시 삭제 완료 (\(files.count)개)")
        } catch {
            print("❌ [KeyringCache] 전체 캐시 삭제 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 캐시 존재 여부

    /// 캐시 파일이 존재하는지 확인 (조용히)
    func exists(for keyringID: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(keyringID).png")
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - 캐시 정보

    /// 전체 캐시 파일 개수 및 용량 반환
    func getCacheInfo() -> (count: Int, totalSize: Int64) {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0

            for file in files where file.pathExtension == "png" {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }

            let sizeString = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
            print("📊 [KeyringCache] 캐시 정보: \(files.count)개 파일, 총 용량 \(sizeString)")

            return (files.count, totalSize)
        } catch {
            print("❌ [KeyringCache] 캐시 정보 조회 실패: \(error.localizedDescription)")
            return (0, 0)
        }
    }

    /// 모든 캐시 파일 목록 출력 (디버깅용)
    func printAllCachedFiles() {
        print("📋 [KeyringCache] ========== 캐시 파일 목록 ==========")
        print("📁 [KeyringCache] 경로: \(cacheDirectory.path)")

        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                .filter { $0.pathExtension == "png" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            if files.isEmpty {
                print("📭 [KeyringCache] 캐시 파일 없음")
                return
            }

            for (index, file) in files.enumerated() {
                let fileName = file.lastPathComponent
                let fileSize = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)

                print("📄 [KeyringCache] \(index + 1). \(fileName) - \(sizeString)")
            }

            let totalSize = files.reduce(Int64(0)) { sum, file in
                let size = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                return sum + size
            }
            let totalSizeString = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)

            print("📊 [KeyringCache] 총 \(files.count)개 파일, 총 용량 \(totalSizeString)")
        } catch {
            print("❌ [KeyringCache] 파일 목록 조회 실패: \(error.localizedDescription)")
        }

        print("📋 [KeyringCache] =====================================")
    }

    /// Finder에서 캐시 폴더 열기 (macOS 시뮬레이터 전용)
    func openCacheDirectoryInFinder() {
        #if targetEnvironment(simulator)
        print("📂 [KeyringCache] Finder에서 캐시 폴더 열기...")
        print("📂 [KeyringCache] 경로: \(cacheDirectory.path)")

        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: cacheDirectory.path)
        #else
        print("⚠️ [KeyringCache] Finder 열기는 시뮬레이터에서만 가능합니다")
        print("📁 [KeyringCache] 경로: \(cacheDirectory.path)")
        #endif
    }
}
