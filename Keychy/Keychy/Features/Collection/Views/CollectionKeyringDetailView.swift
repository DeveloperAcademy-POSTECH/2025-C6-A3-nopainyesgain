//
//  CollectionKeyringDetailView.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI

struct CollectionKeyringDetailView: View {
    var body: some View {
        VStack {
            Text("키링 상세보기 화면")
        }
        .navigationTitle("키링 이름")
    }
        
}

// MARK: - Header Section
extension CollectionKeyringDetailView {
    private var bottomSection: some View {
        HStack(spacing: 0) {
            
        }
    }
}

#Preview {
    CollectionKeyringDetailView()
}
