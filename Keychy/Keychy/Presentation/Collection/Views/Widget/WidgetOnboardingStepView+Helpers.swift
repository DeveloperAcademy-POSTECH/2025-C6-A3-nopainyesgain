//
//  WidgetOnboardingStepView+Helpers.swift
//  Keychy
//
//  Created by Jini on 11/16/25.
//

import SwiftUI

enum HighlightStyle {
    case semibold
    case extrabold
    
    var font: Font {
        switch self {
        case .semibold:
            return .suit16SB
        case .extrabold:
            return .suit16EB
        }
    }
}

struct HighlightKeyword {
    let text: String
    let style: HighlightStyle
    
    init(_ text: String, style: HighlightStyle = .semibold) {
        self.text = text
        self.style = style
    }
}
