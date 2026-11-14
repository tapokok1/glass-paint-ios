import SwiftUI
import PencilKit

enum DrawingToolType: String, CaseIterable, Identifiable {
    case pen = "Перо"
    case pencil = "Карандаш"
    case marker = "Маркер"
    case watercolor = "Акварель"
    case eraser = "Ластик"
    case lasso = "Лассо"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .pen: return "pencil.tip"
        case .pencil: return "pencil.and.outline"
        case .marker: return "paintbrush.pointed"
        case .watercolor: return "drop.fill"
        case .eraser: return "eraser"
        case .lasso: return "lasso"
        }
    }
}

struct PencilCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let toolType: DrawingToolType
    let brushColor: Color
    let brushWidth: CGFloat
    let brushOpacity: Double
    let isDrawingEnabled: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.overrideUserInterfaceStyle = .dark
        updateTool(on: canvasView)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = isDrawingEnabled
        updateTool(on: uiView)
    }

    private func updateTool(on view: PKCanvasView) {
        let uiColor = UIColor(brushColor).withAlphaComponent(CGFloat(brushOpacity))

        switch toolType {
        case .pen:
            view.tool = PKInkingTool(.pen, color: uiColor, width: brushWidth)
        case .pencil:
            view.tool = PKInkingTool(.pencil, color: uiColor, width: brushWidth)
        case .marker:
            view.tool = PKInkingTool(.marker, color: uiColor, width: brushWidth * 1.8)
        case .watercolor:
            view.tool = PKInkingTool(.crayon, color: uiColor, width: brushWidth * 1.5)
        case .eraser:
            view.tool = PKEraserTool(.bitmap, width: brushWidth * 2.0)
        case .lasso:
            view.tool = PKLassoTool()
        }
    }
}
