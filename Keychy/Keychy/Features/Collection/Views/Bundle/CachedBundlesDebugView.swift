//
//  CachedBundlesDebugView.swift
//  Keychy
//
//  Created by Rundo on 11/10/25.
//

import SwiftUI

/// 캐시된 번들 이미지를 확인하는 디버그 뷰
struct CachedBundlesDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cachedImages: [(id: String, name: String, image: Image, size: String)] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if cachedImages.isEmpty {
                        emptyView
                    } else {
                        cacheInfoSection
                        imagesGridSection
                    }
                }
                .padding()
            }
            .navigationTitle("캐시된 번들 이미지")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("새로고침") {
                        loadCachedImages()
                    }
                }
            }
        }
        .onAppear {
            loadCachedImages()
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("캐시된 번들 이미지가 없습니다")
                .font(.headline)
                .foregroundColor(.gray)

            Text("번들을 한 번 열어보면\n번들 이미지가 생성됩니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Cache Info Section

    private var cacheInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("캐시 정보")
                .font(.headline)

            HStack {
                Label("\(cachedImages.count)개 파일", systemImage: "doc.on.doc")

                Spacer()

                let totalSize = cachedImages.reduce(0) { sum, item in
                    let sizeString = item.size.replacingOccurrences(of: " KB", with: "")
                    return sum + (Double(sizeString) ?? 0)
                }
                Label(String(format: "%.1f KB", totalSize), systemImage: "externaldrive")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Button(role: .destructive) {
                clearAllCache()
            } label: {
                Label("전체 캐시 삭제", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    // MARK: - Images Grid Section

    private var imagesGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(cachedImages, id: \.id) { item in
                VStack(spacing: 8) {
                    item.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .background(Color.main500)
                        .cornerRadius(10)

                    VStack(spacing: 4) {
                        Text(item.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Text(item.id)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(item.size)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Button(role: .destructive) {
                        deleteImage(id: item.id)
                    } label: {
                        Label("삭제", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Load Cached Images

    private func loadCachedImages() {

        // 앱 샌드박스의 메타데이터 로드
        let availableBundles = BundleImageCache.shared.loadAvailableBundles()
        var loadedImages: [(id: String, name: String, image: Image, size: String)] = []

        for bundle in availableBundles {
            // 이미지 데이터 로드
            if let imageData = BundleImageCache.shared.loadImageByPath(bundle.imagePath),
               let uiImage = UIImage(data: imageData) {
                let sizeString = String(format: "%.1f KB", Double(imageData.count) / 1024.0)

                loadedImages.append((
                    id: bundle.id,
                    name: bundle.name,
                    image: Image(uiImage: uiImage),
                    size: sizeString
                ))
            }
        }

        cachedImages = loadedImages
    }

    // MARK: - Delete Image

    private func deleteImage(id: String) {
        // 이미지와 메타데이터 모두 삭제
        BundleImageCache.shared.removeBundle(id: id)
        loadCachedImages()
    }

    // MARK: - Clear All Cache

    private func clearAllCache() {
        // 모든 번들 메타데이터 삭제
        let bundles = BundleImageCache.shared.loadAvailableBundles()
        for bundle in bundles {
            BundleImageCache.shared.removeBundle(id: bundle.id)
        }

        // 혹시 남은 이미지 파일도 삭제
        BundleImageCache.shared.clearAll()

        loadCachedImages()
    }
}

#Preview {
    CachedBundlesDebugView()
}
