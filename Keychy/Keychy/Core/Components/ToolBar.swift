//
//  ToolBar.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/20/25.
//

import SwiftUI

struct ToolBar<Route: Hashable>: ToolbarContent {
    let router: NavigationRouter<Route>
    let leadingTitle: String?
    let trailingTitle: String?
    let leadingSystemImageName: String?
    let trailingSystemImageName: String?
    let trailingAction: (() -> Void)?
    let leadingAction: (() -> Void)?
    let nextNavigationTo: Route?
    
    init(
        router: NavigationRouter<Route>,
        leadingTitle: String? = nil,
        trailingTitle: String? = nil,
        leadingSystemImageName: String? = "chevron.left",
        trailingSystemImageName: String? = nil,
        leadingAction: (() -> Void)? = nil,
        trailingAction: (() -> Void)? = nil,
        nextNavigationTo: Route? = nil
    ) {
        self.router = router
        self.leadingTitle = leadingTitle
        self.trailingTitle = trailingTitle
        self.leadingSystemImageName = leadingSystemImageName
        self.trailingSystemImageName = trailingSystemImageName
        self.leadingAction = leadingAction
        self.trailingAction = trailingAction
        self.nextNavigationTo = nextNavigationTo
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                if let leadingAction {
                    leadingAction()
                }
            } label: {
                HStack(spacing: 4) {
                    if let leadingSystemImageName, !leadingSystemImageName.isEmpty {
                        Image(systemName: leadingSystemImageName)
                            .font(.body.weight(.medium))
                    }
                    if let leadingTitle {
                        Text(leadingTitle)
                    }
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                if let trailingAction {
                    trailingAction()
                }
                else {
                    router.pop()
                }
            } label: {
                HStack(spacing: 4) {
                    if let trailingSystemImageName, !trailingSystemImageName.isEmpty {
                        Image(systemName: trailingSystemImageName)
                            .font(.body.weight(.medium))
                    }
                    if let trailingTitle {
                        Text(trailingTitle)
                    }
                }
            }
        }
    }
}
