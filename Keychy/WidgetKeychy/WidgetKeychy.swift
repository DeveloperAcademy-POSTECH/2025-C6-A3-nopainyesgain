//
//  WidgetKeychy.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    /// 위젯 갤러리에서 보여지는 플레이스홀더 (데이터 로드 전)
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    /// 위젯 갤러리 미리보기용 스냅샷
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }

    /// 위젯 업데이트 일정 제공 (앱에서 수동으로 새로고침할 때만 업데이트)
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration)

        // policy: .never - 자동 업데이트 없음, WidgetCenter.reloadTimelines() 호출 시에만 갱신
        return Timeline(entries: [entry], policy: .never)
    }
}

struct WidgetKeychy: Widget {
    let kind: String = "WidgetKeychy"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetKeychyEntryView(entry: entry)
          }
        .containerBackgroundRemovable(true)
        .contentMarginsDisabled()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct WidgetKeychyEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if let selectedKeyring = entry.configuration.selectedKeyring {
            // 키링이 선택된 경우
            keyringView(keyring: selectedKeyring)
        } else {
            // 키링이 선택되지 않은 경우
            placeholderView
        }
    }

    // MARK: - 키링 이미지 뷰
    private func keyringView(keyring: KeyringEntity) -> some View {
        // App Group에서 키링 메타데이터 확인
        let availableKeyrings = KeyringImageCache.shared.loadAvailableKeyrings()

        return Group {
            if let availableKeyring = availableKeyrings.first(where: { $0.id == keyring.id }) {
                // 키링이 존재하고 이미지 로드 가능
                if let imageData = KeyringImageCache.shared.loadImageByPath(availableKeyring.imagePath),
                   let uiImage = UIImage(data: imageData) {
                    VStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    // 이미지 로드 실패
                    placeholderView
                }
            } else {
                // 선택된 키링이 삭제됨
                placeholderView
            }
        }
    }

    // MARK: - 플레이스홀더 뷰
    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.largeTitle)
                .foregroundColor(.white)

            Text("꾹눌러서\n키링을 선택하세요")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.widgetBackground)
    }
}

extension ConfigurationAppIntent {
    fileprivate static var noSelection: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.selectedKeyring = nil
        return intent
    }

    fileprivate static var withKeyring: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.selectedKeyring = KeyringEntity(id: "sample-id", name: "샘플 키링")
        return intent
    }
}

#Preview(as: .systemSmall) {
    WidgetKeychy()
} timeline: {
    SimpleEntry(date: .now, configuration: .noSelection)
    SimpleEntry(date: .now, configuration: .withKeyring)
}
