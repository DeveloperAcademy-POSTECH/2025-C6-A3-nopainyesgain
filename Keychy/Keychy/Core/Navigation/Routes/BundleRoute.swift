//
//  BundleRoute.swift
//  Keychy
//
//  Created seo on 11/18/25.
//

import Foundation

/// Bundle 관련 View들에서 필요한 Route 케이스를 정의하는 프로토콜
protocol BundleRoute: Hashable {
    static var bundleInventoryView: Self { get }
    static var bundleDetailView: Self { get }
    static var bundleCreateView: Self { get }
    static var bundleAddKeyringView: Self { get }
    static var bundleNameInputView: Self { get }
    static var bundleNameEditView: Self { get }
    static var bundleEditView: Self { get }
    static var coinCharge: Self { get }
}
