//
//  BundleImageCache.swift
//  Keychy
//
//  Created by Rundo on 11/10/25.
//

import Foundation
import SwiftUI

/// 번들(MultiKeyring) 썸네일 이미지를 FileManager 기반으로 캐싱 (앱 샌드박스)
class BundleImageCache {
    static let shared = BundleImageCache()

    private let fileManager = FileManager.default
    private let metadataFileName = "available_bundles.json"

    /// 캐시 디렉토리 경로 (앱 샌드박스)
    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let bundleCache = urls[0].appendingPathComponent("BundleThumbnails", isDirectory: true)

        // 디렉토리가 없으면 생성
        if !fileManager.fileExists(atPath: bundleCache.path) {
            do {
                try fileManager.createDirectory(at: bundleCache, withIntermediateDirectories: true)
            } catch {
                print("❌ [BundleCache] 캐시 디렉토리 생성 실패: \(error.localizedDescription)")
            }
        }

        return bundleCache
    }

    /// 메타데이터 파일 URL
    private var metadataFileURL: URL {
        cacheDirectory.appendingPathComponent(metadataFileName)
    }

    private init() {
        // 초기화
    }

    // MARK: - 저장

    /// PNG 데이터를 파일로 저장
    func save(pngData: Data, for bundleID: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(bundleID).png")

        do {
            try pngData.write(to: fileURL)
            
        } catch {
            print("❌ [BundleCache] 저장 실패: \(bundleID) - \(error.localizedDescription)")
        }
    }

    // MARK: - 불러오기

    /// 캐시된 PNG 데이터 로드
    func load(for bundleID: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent("\(bundleID).png")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            print("❌ [BundleCache] 로드 실패: \(bundleID) - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - 삭제

    /// 특정 번들 캐시 삭제
    func delete(for bundleID: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(bundleID).png")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("❌ [BundleCache] 삭제 실패: \(bundleID) - \(error.localizedDescription)")
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
        } catch {
            print("❌ [BundleCache] 전체 캐시 삭제 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 캐시 존재 여부

    /// 캐시 파일이 존재하는지 확인
    func exists(for bundleID: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(bundleID).png")
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - 메타데이터 관리

    /// 사용 가능한 번들 목록 저장
    func saveAvailableBundles(_ bundles: [AvailableBundle]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(bundles)
            try data.write(to: metadataFileURL, options: .atomic)
        } catch {
            print("❌ [BundleCache] 메타데이터 저장 실패: \(error.localizedDescription)")
        }
    }

    /// 사용 가능한 번들 목록 로드
    func loadAvailableBundles() -> [AvailableBundle] {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            print("⚠️ [BundleCache] 메타데이터 파일이 없습니다.")
            return []
        }

        do {
            let data = try Data(contentsOf: metadataFileURL)
            let decoder = JSONDecoder()
            let bundles = try decoder.decode([AvailableBundle].self, from: data)
            return bundles
        } catch {
            print("❌ [BundleCache] 메타데이터 로드 실패: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 동기화 메서드

    /// 번들 추가 또는 업데이트 (이미지 + 메타데이터)
    func syncBundle(id: String, name: String, imageData: Data) {
        // 1. 이미지 저장
        save(pngData: imageData, for: id)

        // 2. 메타데이터 업데이트
        var bundles = loadAvailableBundles()
        let imagePath = "\(id).png"

        if let index = bundles.firstIndex(where: { $0.id == id }) {
            // 기존 번들 업데이트
            bundles[index] = AvailableBundle(id: id, name: name, imagePath: imagePath)
        } else {
            // 새 번들 추가
            bundles.append(AvailableBundle(id: id, name: name, imagePath: imagePath))
        }

        saveAvailableBundles(bundles)
    }

    /// 번들 삭제 (이미지 + 메타데이터)
    func removeBundle(id: String) {
        // 1. 이미지 삭제
        delete(for: id)

        // 2. 메타데이터에서 제거
        var bundles = loadAvailableBundles()
        bundles.removeAll { $0.id == id }
        saveAvailableBundles(bundles)

    }

    /// 이미지 경로로 이미지 로드
    func loadImageByPath(_ imagePath: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(imagePath)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            print("❌ [BundleCache] 이미지 로드 실패: \(imagePath) - \(error.localizedDescription)")
            return nil
        }
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

            return (files.count, totalSize)
        } catch {
            print("❌ [BundleCache] 캐시 정보 조회 실패: \(error.localizedDescription)")
            return (0, 0)
        }
    }

    /// 모든 캐시 파일 목록 출력 (디버깅용)
    func printAllCachedFiles() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                .filter { $0.pathExtension == "png" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            if files.isEmpty {
                return
            }

            for (_, file) in files.enumerated() {
                _ = file.lastPathComponent
                let fileSize = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                _ = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)

            }

            let totalSize = files.reduce(Int64(0)) { sum, file in
                let size = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                return sum + size
            }
            _ = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)

        } catch {
            print("❌ [BundleCache] 파일 목록 조회 실패: \(error.localizedDescription)")
        }
    }
}

/// 번들 메타데이터 구조체
struct AvailableBundle: Codable, Identifiable, Hashable {
    let id: String          // Firestore documentId
    let name: String        // 번들 이름
    let imagePath: String   // 앱 샌드박스 내 이미지 경로
}
