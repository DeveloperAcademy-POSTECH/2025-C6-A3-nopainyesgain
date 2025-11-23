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
    
    @State private var cropPaths: [CropPath] = []
    @State private var currentCropPoints: [CGPoint] = []
    @State private var imageDisplaySize: CGSize = .zero
    @State private var showCropAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .ignoresSafeArea()
                
                ZStack {
                    if let bodyImage = viewModel.bodyImage {
                        cropCanvasView(image: bodyImage, geometry: geometry)
                    } else {
                        ProgressView("이미지 생성 중...")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // MARK: - 커스텀 네비게이션
                customNavigationBar
                
                if showCropAlert {
                    CropAlertPopup(isPresented: $showCropAlert)
                        .zIndex(101)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }
}

// MARK: - Navigation
extension ClearSketchCropView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            Text("가위로 오려주세요")
                .typography(.notosans17M)
        } trailing: {
            NextToolbarButton {
                performCrop()
            }
            .frame(width: 44, height: 44)
            .offset(x: -4)
        }
    }
}

// MARK: - Crop Canvas
extension ClearSketchCropView {
    func cropCanvasView(image: UIImage, geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let displayWidth = screenWidth * 0.8
        let aspectRatio = image.size.height / image.size.width
        let displayHeight = displayWidth * aspectRatio
        
        return ZStack {
            // 배경 이미지
            Image(uiImage: image)
                .resizable()
                .frame(width: displayWidth, height: displayHeight)
                .aspectRatio(contentMode: .fit)
                .background(Color.white)
            
            // 크롭 영역 캔버스
            Canvas { context, size in
                // 크롭 패스들 그리기
                for cropPath in cropPaths {
                    drawCropPath(context: &context, path: cropPath)
                }
                
                // 현재 그리고 있는 크롭 패스
                if !currentCropPoints.isEmpty {
                    let currentPath = CropPath(points: currentCropPoints)
                    drawCropPath(context: &context, path: currentPath)
                }
            }
            .frame(width: displayWidth, height: displayHeight)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = value.location
                        
                        if currentCropPoints.isEmpty {
                            // 새로운 크롭 시작 시 기존 패스 모두 제거
                            cropPaths.removeAll()
                            currentCropPoints = [point]
                            Haptic.impact(style: .light)
                        } else {
                            currentCropPoints.append(point)
                        }
                    }
                    .onEnded { _ in
                        if !currentCropPoints.isEmpty {
                            cropPaths.append(CropPath(points: currentCropPoints))
                            currentCropPoints.removeAll()
                            Haptic.impact(style: .medium)
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            imageDisplaySize = CGSize(width: displayWidth, height: displayHeight)
        }
    }
    
    private func drawCropPath(context: inout GraphicsContext, path: CropPath) {
        let points = path.points
        guard points.count > 1 else { return }
        
        var swiftUIPath = Path()
        
        if path.points.count == 2 {
            swiftUIPath.move(to: path.points[0])
            swiftUIPath.addLine(to: points[1])
        } else {
            // 여러 점일 때는 부드러운 베지어 곡선으로
            swiftUIPath.move(to: points[0])
            
            for i in 1..<points.count {
                let currentPoint = points[i]
                let previousPoint = points[i - 1]
                
                if i == 1 {
                    // 첫 번째 선분은 직선으로
                    swiftUIPath.addLine(to: currentPoint)
                } else {
                    // 이전 점과 현재 점의 중간점을 계산
                    let midPoint = CGPoint(
                        x: (previousPoint.x + currentPoint.x) / 2,
                        y: (previousPoint.y + currentPoint.y) / 2
                    )
                    
                    // 이전 점을 제어점으로 사용하여 부드러운 곡선 생성
                    swiftUIPath.addQuadCurve(
                        to: midPoint,
                        control: previousPoint
                    )
                }
            }
            
            // 마지막 점까지 연결
            if points.count > 1 {
                swiftUIPath.addLine(to: points[points.count - 1])
            }
        }
        
        // 크롭 영역 외곽선 (점선)
        if points.count > 1 {
            context.stroke(
                swiftUIPath,
                with: .color(.main500),
                style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [10, 10]
                )
            )
        }
        
        // 시작점 표시
        if let firstPoint = path.points.first {
            let startCircle = Path(ellipseIn: CGRect(
                x: firstPoint.x - 6,
                y: firstPoint.y - 6,
                width: 12,
                height: 12
            ))
            context.fill(startCircle, with: .color(.main500))
            context.stroke(startCircle, with: .color(.white), lineWidth: 1)
        }
    }
}

// MARK: - Crop Functions
extension ClearSketchCropView {
    private func clearCropPaths() {
        cropPaths.removeAll()
        currentCropPoints.removeAll()
    }
    
    private func autoDetectCrop() {
        guard let bodyImage = viewModel.bodyImage else { return }
        
        let contentBounds = detectContentBounds(in: bodyImage)
        
        // 감지된 영역을 크롭 패스로 변환 (화면 좌표계)
        let imageDisplaySize = imageDisplaySize
        let imageOriginalSize = bodyImage.size
        
        let scaleX = imageDisplaySize.width / imageOriginalSize.width
        let scaleY = imageDisplaySize.height / imageOriginalSize.height
        
        let cropPath = CropPath(points: [
            CGPoint(x: contentBounds.minX * scaleX, y: contentBounds.minY * scaleY),
            CGPoint(x: contentBounds.maxX * scaleX, y: contentBounds.minY * scaleY),
            CGPoint(x: contentBounds.maxX * scaleX, y: contentBounds.maxY * scaleY),
            CGPoint(x: contentBounds.minX * scaleX, y: contentBounds.maxY * scaleY)
        ])
        
        clearCropPaths()
        cropPaths = [cropPath]
    }
    
    private func detectContentBounds(in image: UIImage) -> CGRect {
        guard let cgImage = image.cgImage else {
            return CGRect(x: 20, y: 20, width: image.size.width - 40, height: image.size.height - 40)
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return CGRect(x: 20, y: 20, width: image.size.width - 40, height: image.size.height - 40)
        }
        
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        
        let bytesPerPixel = 4
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let alpha = bytes[offset + 3]
                
                // 투명하지 않은 픽셀 감지 (알파값 체크)
                if alpha > 30 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        
        // 콘텐츠를 찾지 못한 경우 기본값
        if minX >= width || minY >= height {
            return CGRect(x: 20, y: 20, width: image.size.width - 40, height: image.size.height - 40)
        }
        
        // 여백 추가
        let margin = 15
        minX = max(0, minX - margin)
        minY = max(0, minY - margin)
        maxX = min(width - 1, maxX + margin)
        maxY = min(height - 1, maxY + margin)
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func performCrop() {
        guard let bodyImage = viewModel.bodyImage else { return }
        
        // 크롭 영역이 없거나 점이 2개 미만이면 경고 표시
        guard !cropPaths.isEmpty,
              let cropPoints = cropPaths.first?.points,
              cropPoints.count >= 2 else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showCropAlert = true
            }
            return
        }
        
        // 크롭된 이미지 생성
        guard let croppedImage = viewModel.cropImageWithPath(
            image: bodyImage,
            cropPath: cropPoints,
            imageDisplaySize: imageDisplaySize
        ) else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showCropAlert = true
            }
            return
        }
        
        // 크롭 결과 저장
        viewModel.croppedImage = croppedImage
        
        // 이미지 처리 후 다음 화면으로
        Task {
            await viewModel.processImageForCustomizing()
            await MainActor.run {
                router.push(.clearSketchCustomizing)
            }
        }
    }
    
    private func autoCropImage(_ image: UIImage, bounds: CGRect) -> UIImage {
        guard let cgImage = image.cgImage?.cropping(to: bounds) else {
            return image
        }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - CropPath 구조체
struct CropPath: Identifiable {
    let id = UUID()
    var points: [CGPoint] = []
}

// MARK: - 크롭 알럿
struct CropAlertPopup: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Text("크롭 영역을 지정해주세요.")
            .typography(.suit17SB)
            .foregroundColor(.black100)
            .frame(width: 300, height: 73)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            }
    }
}
