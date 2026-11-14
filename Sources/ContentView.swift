import SwiftUI
import PencilKit
import PhotosUI

struct ContentView: View {
    @StateObject private var model = CanvasModel()

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isShowingAdjustments: Bool = false
    @State private var isShowingLayers: Bool = false
    @State private var isShowingBrushSettings: Bool = false
    @State private var isShowingClearAlert: Bool = false
    @State private var exportedImage: UIImage? = nil
    @State private var isShowingShareSheet: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Atmosphere (Ambient Liquid Glow)
                ambientBackground

                // Canvas Area (Photos + Vector Drawing)
                canvasArea(size: geometry.size)

                // Top Floating Glass Navigation Bar
                VStack(spacing: 0) {
                    topNavigationBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    Spacer()

                    // Quick Mode & Status Toast (if any)
                    if let message = model.statusMessage {
                        statusToast(message: message)
                            .padding(.bottom, 8)
                    }

                    // Bottom Floating Liquid Glass Studio Dock
                    bottomStudioDock
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $isShowingAdjustments) {
            AdjustmentsSheetView(model: model)
        }
        .sheet(isPresented: $isShowingLayers) {
            LayersSheetView(model: model)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let img = exportedImage {
                ShareActivityView(image: img)
            }
        }
        .alert("Очистить холст?", isPresented: $isShowingClearAlert) {
            Button("Очистить всё", role: .destructive) {
                model.clearDrawing()
                model.photoLayers.removeAll()
                model.selectedLayerId = nil
            }
            Button("Только рисунок", role: .destructive) {
                model.clearDrawing()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вы хотите удалить рисунок или весь проект?")
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        model.addPhotoLayer(image: uiImage)
                        selectedPhotoItem = nil
                    }
                }
            }
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.09)
                .ignoresSafeArea()

            // Subtle liquid light orbs
            Circle()
                .fill(Color.cyan.opacity(0.12))
                .blur(radius: 90)
                .offset(x: -120, y: -250)

            Circle()
                .fill(Color.purple.opacity(0.1))
                .blur(radius: 110)
                .offset(x: 140, y: 300)
        }
    }

    // MARK: - Canvas Area

    private func canvasArea(size: CGSize) -> some View {
        ZStack {
            // 1. Canvas Background Tone
            Group {
                switch model.backgroundStyle {
                case .dark:
                    Color(red: 0.09, green: 0.10, blue: 0.14)
                case .light:
                    Color.white
                case .transparent:
                    CheckerboardGrid()
                }
            }
            .ignoresSafeArea()

            // 2. Photo Layers
            ForEach($model.photoLayers) { $layer in
                PhotoLayerItemView(
                    layer: $layer,
                    isSelected: model.selectedLayerId == layer.id,
                    isDrawingMode: model.isDrawingMode,
                    onSelect: {
                        model.selectedLayerId = layer.id
                    }
                )
            }

            // 3. Vector PencilKit Strokes
            PencilCanvasRepresentable(
                canvasView: .constant(model.pkCanvasView),
                toolType: model.drawingTool,
                brushColor: model.brushColor,
                brushWidth: model.brushWidth,
                brushOpacity: model.brushOpacity,
                isDrawingEnabled: model.isDrawingMode
            )
        }
    }

    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        HStack(spacing: 12) {
            // App Branding
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.cyan)

                Text("GlassPaint")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.leading, 4)

            Spacer()

            // Mode Selector (Draw vs Transform)
            HStack(spacing: 4) {
                modePill(
                    title: "Кисть",
                    icon: "paintbrush.pointed",
                    isActive: model.isDrawingMode
                ) {
                    model.isDrawingMode = true
                }

                modePill(
                    title: "Фото",
                    icon: "arrow.up.and.down.and.arrow.left.and.right",
                    isActive: !model.isDrawingMode
                ) {
                    model.isDrawingMode = false
                }
            }
            .padding(4)
            .background(Capsule().fill(Color.white.opacity(0.08)))

            Spacer()

            // Undo / Redo / Share
            HStack(spacing: 8) {
                GlassIconButton(systemName: "arrow.uturn.backward") {
                    model.undo()
                }

                GlassIconButton(systemName: "arrow.uturn.forward") {
                    model.redo()
                }

                GlassIconButton(systemName: "square.and.arrow.up", tint: .cyan) {
                    exportAndShare()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .liquidGlass(cornerRadius: 24, opacity: 0.85)
    }

    private func modePill(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isActive ? Color.black : Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                if isActive {
                    Capsule().fill(Color.cyan)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Studio Dock

    private var bottomStudioDock: some View {
        VStack(spacing: 10) {
            // Secondary Quick Bar for Brush controls when in drawing mode
            if isShowingBrushSettings && model.isDrawingMode {
                brushSettingsGlassCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Main Dock Strip
            HStack(spacing: 12) {
                // Drawing Tools Menu
                Menu {
                    ForEach(DrawingToolType.allCases) { tool in
                        Button {
                            model.drawingTool = tool
                            model.isDrawingMode = true
                        } label: {
                            Label(tool.rawValue, systemImage: tool.systemIcon)
                        }
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: model.drawingTool.systemIcon)
                            .font(.system(size: 17, weight: .semibold))
                        Text(model.drawingTool.rawValue)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(model.isDrawingMode ? Color.cyan : Color.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                }

                // Brush Settings Toggle (Size & Opacity)
                GlassIconButton(
                    systemName: "slider.horizontal.3",
                    title: "Размер",
                    isSelected: isShowingBrushSettings
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isShowingBrushSettings.toggle()
                    }
                }

                // Color Picker
                ColorPicker("", selection: $model.brushColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .padding(4)

                // Add Photo from Library
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 3) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Фото")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                }

                // Edit Photo / Cutout Button
                GlassIconButton(
                    systemName: "person.crop.rectangle.badge.plus",
                    title: "Вырезка",
                    isSelected: model.selectedLayer != nil && !model.isDrawingMode
                ) {
                    if model.selectedLayer != nil {
                        isShowingAdjustments = true
                    } else if let last = model.photoLayers.last {
                        model.selectedLayerId = last.id
                        model.isDrawingMode = false
                        isShowingAdjustments = true
                    }
                }

                // Layers Drawer
                GlassIconButton(
                    systemName: "square.2.layers.3d",
                    title: "Слои",
                    isSelected: isShowingLayers
                ) {
                    isShowingLayers = true
                }

                // Clear Canvas
                GlassIconButton(systemName: "trash", tint: .red.opacity(0.85)) {
                    isShowingClearAlert = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .liquidGlass(cornerRadius: 28, opacity: 0.85)
        }
    }

    // MARK: - Brush Settings Glass Card

    private var brushSettingsGlassCard: some View {
        VStack(spacing: 12) {
            // Brush Width Slider
            HStack(spacing: 12) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))

                Slider(value: $model.brushWidth, in: 1.0...60.0)
                    .tint(Color.cyan)

                Image(systemName: "circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.6))

                Text("\(Int(model.brushWidth)) pt")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color.cyan)
                    .frame(width: 44, alignment: .trailing)
            }

            // Brush Opacity Slider
            HStack(spacing: 12) {
                Image(systemName: "drop")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))

                Slider(value: $model.brushOpacity, in: 0.1...1.0)
                    .tint(Color.cyan)

                Image(systemName: "drop.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))

                Text("\(Int(model.brushOpacity * 100))%")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color.cyan)
                    .frame(width: 44, alignment: .trailing)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 20, opacity: 0.8)
    }

    // MARK: - Status Toast

    private func statusToast(message: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(Color.cyan)
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 16, opacity: 0.9)
    }

    // MARK: - Export Action

    private func exportAndShare() {
        let size = UIScreen.main.bounds.size
        let composite = model.exportCompositeImage(canvasSize: size)
        self.exportedImage = composite
        self.isShowingShareSheet = true
    }
}

// MARK: - Transparent Checkerboard Grid

struct CheckerboardGrid: View {
    let size: CGFloat = 16

    var body: some View {
        Canvas { context, canvasSize in
            let cols = Int(canvasSize.width / size) + 1
            let rows = Int(canvasSize.height / size) + 1

            for col in 0..<cols {
                for row in 0..<rows {
                    if (col + row) % 2 == 0 {
                        let rect = CGRect(
                            x: CGFloat(col) * size,
                            y: CGFloat(row) * size,
                            width: size,
                            height: size
                        )
                        context.fill(Path(rect), with: .color(Color(white: 0.15)))
                    } else {
                        let rect = CGRect(
                            x: CGFloat(col) * size,
                            y: CGFloat(row) * size,
                            width: size,
                            height: size
                        )
                        context.fill(Path(rect), with: .color(Color(white: 0.10)))
                    }
                }
            }
        }
    }
}

// MARK: - UIActivityViewController Wrapper for Sharing

struct ShareActivityView: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
