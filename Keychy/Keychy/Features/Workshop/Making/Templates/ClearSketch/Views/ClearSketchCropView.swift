//
//  ClearSketchCropView.swift
//  Keychy
//
//  Created by Jini on 11/23/25.
//

import SwiftUI

struct ClearSketchCropView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: ClearSketchVM

    @State private var isImageLoading = true
    
    var body: some View {
        ZStack {
            Text("Hello, World!")
            
            customNavigationBar
        }
        
        
        
    }
}

// MARK: - Toolbar
extension ClearSketchCropView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                viewModel.resetImageData()
                router.pop()
            }
        } center: {
            Text("가위로 오려주세요")
                .typography(.notosans17M)
        } trailing: {
            NextToolbarButton {
//                guard let cropped = viewModel.cropImage(
//                    image: viewModel.selectedImage!,
//                    cropArea: viewModel.cropArea,
//                    containerSize: viewModel.imageViewSize
//                ) else {
//                    return
//                }
//                viewModel.croppedImage = cropped
                router.push(.clearSketchCustomizing)
            }
            .frame(width: 44, height: 44)
            .offset(x: -4)
        }
    }
}
