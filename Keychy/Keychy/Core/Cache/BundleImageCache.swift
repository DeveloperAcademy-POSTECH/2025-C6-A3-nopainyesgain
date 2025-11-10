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
//            print("✅ [BundleCache] 이미지 저장: \(bundleID)")
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
//            print("✅ [BundleCache] 이미지 삭제: \(bundleID)")
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
//            print("✅ [BundleCache] 전체 캐시 삭제 완료")
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
//            print("✅ [BundleCache] \(bundles.count)개 번들 메타데이터 저장 완료")
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
//            print("✅ [BundleCache] \(bundles.count)개 번들 메타데이터 로드 완료")
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
//            print("✅ [BundleCache] 번들 업데이트: \(name)")
        } else {
            // 새 번들 추가
            bundles.append(AvailableBundle(id: id, name: name, imagePath: imagePath))
//            print("✅ [BundleCache] 새 번들 추가: \(name)")
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

//        print("✅ [BundleCache] 번들 완전 삭제: \(id)")
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
        print("📋 [BundleCache] ========== 캐시 파일 목록 ==========")
        print("📁 [BundleCache] 경로: \(cacheDirectory.path)")

        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                .filter { $0.pathExtension == "png" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            if files.isEmpty {
                print("📭 [BundleCache] 캐시 파일 없음")
                return
            }

            for (index, file) in files.enumerated() {
                let fileName = file.lastPathComponent
                let fileSize = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)

                print("📄 [BundleCache] \(index + 1). \(fileName) - \(sizeString)")
            }

            let totalSize = files.reduce(Int64(0)) { sum, file in
                let size = (try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
                return sum + size
            }
            let totalSizeString = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)

            print("📊 [BundleCache] 총 \(files.count)개 파일, 총 용량 \(totalSizeString)")
        } catch {
            print("❌ [BundleCache] 파일 목록 조회 실패: \(error.localizedDescription)")
        }

        print("📋 [BundleCache] =====================================")
    }
}

/// 번들 메타데이터 구조체
struct AvailableBundle: Codable, Identifiable, Hashable {
    let id: String          // Firestore documentId
    let name: String        // 번들 이름
    let imagePath: String   // 앱 샌드박스 내 이미지 경로
}
