//
//  WidgetKeychyLiveActivity.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetKeychyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WidgetKeychyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WidgetKeychyAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WidgetKeychyAttributes {
    fileprivate static var preview: WidgetKeychyAttributes {
        WidgetKeychyAttributes(name: "World")
    }
}

extension WidgetKeychyAttributes.ContentState {
    fileprivate static var smiley: WidgetKeychyAttributes.ContentState {
        WidgetKeychyAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WidgetKeychyAttributes.ContentState {
         WidgetKeychyAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WidgetKeychyAttributes.preview) {
   WidgetKeychyLiveActivity()
} contentStates: {
    WidgetKeychyAttributes.ContentState.smiley
    WidgetKeychyAttributes.ContentState.starEyes
}
