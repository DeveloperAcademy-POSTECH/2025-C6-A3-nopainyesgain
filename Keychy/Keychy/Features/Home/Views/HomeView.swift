//
//  HomeView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct HomeView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    @Namespace private var unionNamespace
    
    var body: some View {
        HStack {
            Button {
                router.push(.bundleInventoryView)
            } label: {
                Image(.bundleIcon)
            }
            .buttonStyle(.glassProminent)
            
            GlassEffectContainer {
                HStack(spacing: 0) {
                    Button {
                        router.push(.alarmView)
                    } label: {
                        Image(.alarmIcon)
                    }
                    .buttonStyle(.glassProminent)
                    .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)


                    Button {
                        router.push(.coinCharge)
                    } label: {
                        Image(.myPageIcon)
                    }
                    .buttonStyle(.glassProminent)
                    .glassEffectUnion(id: "mapOptions", namespace: unionNamespace)
                }
            }
        }
        .tint(.white.opacity(0.8))
    }
}
