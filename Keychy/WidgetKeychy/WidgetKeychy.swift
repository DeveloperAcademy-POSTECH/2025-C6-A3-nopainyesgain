//
//  WidgetKeychy.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider (AppIntent)
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .never)
    }
}

// MARK: - Widget
struct WidgetKeychy: Widget {
    let kind: String = "WidgetKeychy"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetKeychyEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Keychy 위젯")
        .description("키링을 표시합니다")
        .contentMarginsDisabled()
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

// MARK: - Entry View
struct WidgetKeychyEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        if let selectedKeyring = entry.configuration.selectedKeyring,
           let imageData = KeyringImageCache.shared.loadImageByPath("\(selectedKeyring.id).png"),
           let uiImage = UIImage(data: imageData) {
            // 선택된 키링 이미지 표시
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            // 플레이스홀더
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                Text("키링 선택")
                    .font(.caption)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
    }
}
