import SwiftUI
import PencilKit
import Combine

enum CanvasBackgroundStyle: String, CaseIterable, Identifiable {
    case dark = "Тёмный"
    case light = "Светлый"
    case transparent = "Сетка"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .transparent: return "checkerboard.rectangle"
        }
    }
}

final class CanvasModel: ObservableObject {
    @Published var photoLayers: [PhotoLayer] = []
    @Published var selectedLayerId: UUID? = nil

    @Published var drawingTool: DrawingToolType = .pen
    @Published var brushColor: Color = .cyan
    @Published var brushWidth: CGFloat = 8.0
    @Published var brushOpacity: Double = 1.0

    @Published var isDrawingMode: Bool = true
    @Published var backgroundStyle: CanvasBackgroundStyle = .dark
    @Published var isProcessingCutout: Bool = false
    @Published var statusMessage: String? = nil

    // PencilKit reference
    let pkCanvasView = PKCanvasView()

    var selectedLayer: PhotoLayer? {
        guard let id = selectedLayerId else { return nil }
        return photoLayers.first(where: { $0.id == id })
    }

    // MARK: - Layer Actions

    func addPhotoLayer(image: UIImage) {
        let newLayer = PhotoLayer(
            title: "Фото \(photoLayers.count + 1)",
            image: image,
            position: .zero,
            scale: 0.85
        )
        photoLayers.append(newLayer)
        selectedLayerId = newLayer.id
        isDrawingMode = false // Switch to transform mode so user can position photo immediately
    }

    func deleteSelectedLayer() {
        guard let id = selectedLayerId else { return }
        photoLayers.removeAll(where: { $0.id == id })
        selectedLayerId = photoLayers.last?.id
        if photoLayers.isEmpty {
            isDrawingMode = true
        }
    }

    func duplicateSelectedLayer() {
        guard let layer = selectedLayer else { return }
        let duplicated = PhotoLayer(
            title: "\(layer.title) (Копия)",
            image: layer.originalImage,
            position: CGPoint(x: layer.position.x + 20, y: layer.position.y + 20),
            scale: layer.scale,
            rotation: layer.rotation,
            opacity: layer.opacity,
            isVisible: layer.isVisible,
            isLocked: false,
            hasCutout: layer.hasCutout,
            adjustments: layer.adjustments
        )
        photoLayers.append(duplicated)
        selectedLayerId = duplicated.id
    }

    func toggleLayerVisibility(id: UUID) {
        if let idx = photoLayers.firstIndex(where: { $0.id == id }) {
            photoLayers[idx].isVisible.toggle()
        }
    }

    func toggleLayerLock(id: UUID) {
        if let idx = photoLayers.firstIndex(where: { $0.id == id }) {
            photoLayers[idx].isLocked.toggle()
        }
    }

    // MARK: - Background Removal (AI/Vision Cutout)

    func removeBackgroundForSelected() {
        guard let id = selectedLayerId,
              let index = photoLayers.firstIndex(where: { $0.id == id }) else { return }

        let targetImage = photoLayers[index].originalImage
        isProcessingCutout = true
        statusMessage = "Вырезание фона..."

        BackgroundRemover.shared.removeBackground(from: targetImage) { [weak self] result in
            guard let self = self else { return }
            self.isProcessingCutout = false
            self.statusMessage = nil

            switch result {
            case .success(let cutoutImage):
                if let idx = self.photoLayers.firstIndex(where: { $0.id == id }) {
                    self.photoLayers[idx].displayImage = cutoutImage
                    self.photoLayers[idx].hasCutout = true
                    // Reapply existing adjustments
                    self.reapplyAdjustments(at: idx)
                }
            case .failure(let error):
                print("Cutout failed: \(error.localizedDescription)")
            }
        }
    }

    func restoreOriginalBackgroundForSelected() {
        guard let id = selectedLayerId,
              let idx = photoLayers.firstIndex(where: { $0.id == id }) else { return }

        photoLayers[idx].hasCutout = false
        photoLayers[idx].displayImage = photoLayers[idx].originalImage
        reapplyAdjustments(at: idx)
    }

    // MARK: - Adjustments & Filters

    func updateAdjustmentsForSelected(_ adjustments: ImageAdjustments) {
        guard let id = selectedLayerId,
              let idx = photoLayers.firstIndex(where: { $0.id == id }) else { return }

        photoLayers[idx].adjustments = adjustments
        reapplyAdjustments(at: idx)
    }

    private func reapplyAdjustments(at index: Int) {
        let base = photoLayers[index].hasCutout ? photoLayers[index].displayImage : photoLayers[index].originalImage
        let adjusted = ImageEditorService.shared.applyAdjustments(to: base, adjustments: photoLayers[index].adjustments)
        photoLayers[index].displayImage = adjusted
    }

    // MARK: - Canvas Controls

    func undo() {
        if isDrawingMode {
            pkCanvasView.undoManager?.undo()
        }
    }

    func redo() {
        if isDrawingMode {
            pkCanvasView.undoManager?.redo()
        }
    }

    func clearDrawing() {
        pkCanvasView.drawing = PKDrawing()
    }

    // MARK: - Composite High-Resolution Export

    func exportCompositeImage(canvasSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            let cgContext = context.cgContext

            // 1. Background Fill
            switch backgroundStyle {
            case .dark:
                UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0).setFill()
                cgContext.fill(CGRect(origin: .zero, size: canvasSize))
            case .light:
                UIColor.white.setFill()
                cgContext.fill(CGRect(origin: .zero, size: canvasSize))
            case .transparent:
                // Transparent output for PNG
                break
            }

            // 2. Render Photo Layers (in z-order)
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            for layer in photoLayers where layer.isVisible {
                cgContext.saveGState()

                let image = layer.displayImage
                let layerCenter = CGPoint(x: center.x + layer.position.x, y: center.y + layer.position.y)

                cgContext.translateBy(x: layerCenter.x, y: layerCenter.y)
                cgContext.rotate(by: CGFloat(layer.rotation.radians))
                cgContext.scaleBy(x: layer.scale, y: layer.scale)
                cgContext.setAlpha(CGFloat(layer.opacity))

                let drawRect = CGRect(
                    x: -image.size.width / 2,
                    y: -image.size.height / 2,
                    width: image.size.width,
                    height: image.size.height
                )
                image.draw(in: drawRect)

                cgContext.restoreGState()
            }

            // 3. Render PencilKit Strokes
            let drawingImage = pkCanvasView.drawing.image(from: CGRect(origin: .zero, size: canvasSize), scale: 2.0)
            drawingImage.draw(in: CGRect(origin: .zero, size: canvasSize))
        }
    }
}
