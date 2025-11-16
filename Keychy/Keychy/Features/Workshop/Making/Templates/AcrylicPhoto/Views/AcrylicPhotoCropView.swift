import SwiftUI

struct AcrylicPhotoCropView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: AcrylicPhotoVM

    @State private var isImageLoading = true

    var body: some View {
        ZStack {
            // 배경색
            Color.clear
                .ignoresSafeArea()

            // MARK: - 이미지 & 크롭 박스
            GeometryReader { geo in
                ZStack {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(isImageLoading ? 0 : 1)
                            .onAppear {
                                setupImageAndCropArea(containerSize: geo.size)
                            }
                            .onChange(of: geo.size) { _, newSize in
                                viewModel.imageViewSize = newSize
                                viewModel.resetToCenter()
                            }
                    }

                    // 크롭박스 바깥 영역 어둡게 (이미지 영역 내에서만)
                    if !isImageLoading {
                        DimmingOverlay(
                            cropRect: viewModel.cropArea,
                            imageRect: viewModel.getDisplayedImageRect()
                        )

                        // 크롭박스
                        CropBoxView(
                            rect: $viewModel.cropArea,
                            onDragChanged: viewModel.onDragChanged,
                            onDragEnd: viewModel.onDragEnd
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 70)

            // 로딩 인디케이터
            if isImageLoading {
                LoadingAlert(type: .short, message: nil)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(true)
        .toolbar {
            backToolbarItem
            naivgationTitle
            nextToolbarItem
        }
    }

    // MARK: - Setup Methods
    private func setupImageAndCropArea(containerSize: CGSize) {
        viewModel.imageViewSize = containerSize
        viewModel.fixedImage = viewModel.selectedImage?.fixedOrientation()

        if !viewModel.hasCropAreaBeenSet {
            viewModel.resetToCenter()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isImageLoading = false
        }
    }
}

// MARK: - Toolbar
extension AcrylicPhotoCropView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            BackToolbarButton {
                viewModel.resetImageData()
                router.pop()
            }
        }
    }
    
    private var naivgationTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            NavigationTitle(title: "누끼 영역을 지정해주세요")
        }
    }

    private var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NextToolbarButton {
                guard let cropped = viewModel.cropImage(
                    image: viewModel.selectedImage!,
                    cropArea: viewModel.cropArea,
                    containerSize: viewModel.imageViewSize
                ) else {
                    return
                }

                viewModel.croppedImage = cropped
                // 크롭만 하고 바로 다음 화면으로 이동 (배경 제거는 EditedView에서)
                router.push(.acrylicPhotoEdited)
            }
        }
    }
}

// MARK: - DimmingOverlay (크롭박스 바깥 어둡게)
struct DimmingOverlay: View {
    let cropRect: CGRect
    let imageRect: CGRect

    var body: some View {
        // 이미지 영역 내에서만 디밍 효과 적용
        Color.black.opacity(0.6)
            .frame(width: imageRect.width, height: imageRect.height)
            .position(x: imageRect.midX, y: imageRect.midY)
            .reverseMask {
                Rectangle()
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
            }
            .allowsHitTesting(false)
    }
}

// MARK: - ReverseMask Extension
extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: .center) {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}

// MARK: - CropBoxView
struct CropBoxView: View {
    @Binding var rect: CGRect
    var onDragChanged: (CGPoint, CGSize) -> Void
    var onDragEnd: () -> Void
    
    @State private var initialRect: CGRect? = nil
    @State private var draggedCorner: UIRectCorner? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                pins
                grid
            }
            .overlay(
                Rectangle()
                    .strokeBorder(.white, lineWidth: 1)
            )
            .background(.white.opacity(0.001))
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .contentShape(Rectangle())
            .gesture(rectDrag)
        }
    }
    
    private var rectDrag: some Gesture {
        DragGesture()
            .onChanged { gesture in
                if initialRect == nil {
                    initialRect = rect
                    draggedCorner = closestCorner(point: gesture.startLocation, rect: rect)
                }
                
                // viewModel에 위임
                onDragChanged(gesture.startLocation, gesture.translation)
            }
            .onEnded { _ in
                initialRect = nil
                draggedCorner = nil
                onDragEnd()
            }
    }
    
    private var pins: some View {
        VStack {
            HStack {
                pin(corner: .topLeft)
                Spacer()
                pin(corner: .topRight)
            }
            Spacer()
            HStack {
                pin(corner: .bottomLeft)
                Spacer()
                pin(corner: .bottomRight)
            }
        }
        .padding(-4)
    }
    
    private func pin(corner: UIRectCorner) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.5), lineWidth: 1.5)
            )
    }
    
    private var grid: some View {
        ZStack {
            HStack {
                Spacer()
                Rectangle()
                    .frame(width: 0.5)
                    .frame(maxHeight: .infinity)
                Spacer()
                Rectangle()
                    .frame(width: 0.5)
                    .frame(maxHeight: .infinity)
                Spacer()
            }
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                Spacer()
                Rectangle()
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .foregroundColor(.white.opacity(0.6))
    }
    
    private func closestCorner(point: CGPoint, rect: CGRect, distance: CGFloat = 44) -> UIRectCorner? {
        let ldX = abs(rect.minX.distance(to: point.x)) < distance
        let rdX = abs(rect.maxX.distance(to: point.x)) < distance
        let tdY = abs(rect.minY.distance(to: point.y)) < distance
        let bdY = abs(rect.maxY.distance(to: point.y)) < distance
        
        guard (ldX || rdX) && (tdY || bdY) else { return nil }
        
        return if ldX && tdY { .topLeft }
        else if rdX && tdY { .topRight }
        else if ldX && bdY { .bottomLeft }
        else if rdX && bdY { .bottomRight }
        else { nil }
    }
}
