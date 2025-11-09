//
//  WidgetKeychy.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
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
    @ViewBuilder
    private func keyringView(keyring: KeyringEntity) -> some View {
        // App Group에서 키링 메타데이터 확인
        let availableKeyrings = KeyringImageCache.shared.loadAvailableKeyrings()

        if let availableKeyring = availableKeyrings.first(where: { $0.id == keyring.id }) {
            // 키링이 존재하고 이미지 로드 가능
            if let imageData = KeyringImageCache.shared.loadImageByPath(availableKeyring.imagePath),
               let uiImage = UIImage(data: imageData) {
                VStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()

                    Text(availableKeyring.name)
                        .font(.caption)
                        .lineLimit(1)
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

    // MARK: - 플레이스홀더 뷰
    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.largeTitle)
                .foregroundColor(.gray)

            Text("꾹눌러서\n키링을 선택하세요")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
    }
}

struct WidgetKeychy: Widget {
    let kind: String = "WidgetKeychy"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetKeychyEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
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
