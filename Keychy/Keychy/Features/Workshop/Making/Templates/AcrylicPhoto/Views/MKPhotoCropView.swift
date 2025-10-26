import SwiftUI

struct MKPhotoCropView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: MKViewModel
    
    var body: some View {
        ZStack {
            // MARK: - 이미지 & 크롭 박스
            GeometryReader { geo in
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            viewModel.imageViewSize = geo.size
                            viewModel.fixedImage = viewModel.selectedImage?.fixedOrientation()
                            if !viewModel.hasCropAreaBeenSet {
                                                    viewModel.resetToCenter()
                                                }
                        }
                        .onChange(of: geo.size) { _, newSize in
                            viewModel.imageViewSize = newSize
                            // 무조건 다시 계산 (처음 설정이 잘못된 거 보정)
                            viewModel.resetToCenter()
                        }
                }
            }
            .overlay(
                CropBoxView(
                    rect: $viewModel.cropArea,
                    onDragChanged: viewModel.onDragChanged,
                    onDragEnd: viewModel.onDragEnd
                )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 70)
            
            // MARK: - 로딩 오버레이
            if viewModel.isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("이미지 처리 중...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.8))
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
    }
}

// MARK: - Toolbar
extension MKPhotoCropView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }
    
    private var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("다음") {
                guard let cropped = viewModel.cropImage(
                    image: viewModel.selectedImage!,
                    cropArea: viewModel.cropArea,
                    containerSize: viewModel.imageViewSize
                ) else {
                    return
                }
                
                viewModel.croppedImage = cropped
                viewModel.isProcessing = true
                
                MKViewModel.removeBackground(from: viewModel.croppedImage) { result in
                    if let result = result {
                        viewModel.removedBackgroundImage = result
                    } else {
                        viewModel.removedBackgroundImage = viewModel.croppedImage
                    }
                    
                    viewModel.isProcessing = false
                    router.push(.mkEditedPhoto)
                }
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
                grid
                pins
            }
            .border(.white, width: 2)
            .background(Color.white.opacity(0.001))
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
        .padding(8)
    }

    private func pin(corner: UIRectCorner) -> some View {
        let cornerLength: CGFloat = 10
        let lineWidth: CGFloat = 3
        
        switch corner {
        case .topLeft:
            return AnyView(
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: cornerLength, height: lineWidth)
                    Rectangle()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: lineWidth, height: cornerLength)
                }
                .offset(x: -cornerLength, y: -cornerLength)
            )
        case .topRight:
            return AnyView(
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: cornerLength, height: lineWidth)
                    Rectangle()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: lineWidth, height: cornerLength)
                }
                .offset(x: cornerLength, y: -cornerLength)
            )
        case .bottomLeft:
            return AnyView(
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: cornerLength, height: lineWidth)
                    Rectangle()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: lineWidth, height: cornerLength)
                }
                .offset(x: -cornerLength, y: cornerLength)
            )
        case .bottomRight:
            return AnyView(
                ZStack(alignment: .bottomTrailing) {
                    Rectangle()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: cornerLength, height: lineWidth)
                    Rectangle()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: lineWidth, height: cornerLength)
                }
                .offset(x: cornerLength, y: cornerLength)
            )
        default:
            return AnyView(EmptyView())
        }
    }

    private var grid: some View {
        ZStack {
            HStack {
                Spacer()
                Rectangle()
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                Spacer()
                Rectangle()
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                Spacer()
            }
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .foregroundColor(.white.opacity(0.4))
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
