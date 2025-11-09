//
//  WidgetKeychyBundle.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import WidgetKit
import SwiftUI

@main
struct WidgetKeychyBundle: WidgetBundle {
    var body: some Widget {
        WidgetKeychy()
        WidgetKeychyControl()
        WidgetKeychyLiveActivity()
    }
}
