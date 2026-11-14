import SwiftUI

struct PhotoLayerItemView: View {
    @Binding var layer: PhotoLayer
    let isSelected: Bool
    let isDrawingMode: Bool
    let onSelect: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero

    var body: some View {
        if layer.isVisible {
            Image(uiImage: layer.displayImage)
                .resizable()
                .scaledToFit()
                .opacity(layer.opacity)
                .frame(maxWidth: 320, maxHeight: 320)
                .overlay {
                    if isSelected && !isDrawingMode && !layer.isLocked {
                        // Liquid glass selection frame with handles
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.cyan, Color.white, Color.cyan.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                            .overlay(alignment: .topTrailing) {
                                Circle()
                                    .fill(Color.cyan)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .offset(x: 6, y: -6)
                            }
                            .overlay(alignment: .bottomLeading) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Color.cyan, lineWidth: 2))
                                    .offset(x: -6, y: 6)
                            }
                    }
                }
                .scaleEffect(layer.scale * currentScale)
                .rotationEffect(layer.rotation + currentRotation)
                .offset(
                    x: layer.position.x + dragOffset.width,
                    y: layer.position.y + dragOffset.height
                )
                .onTapGesture {
                    if !isDrawingMode {
                        onSelect()
                    }
                }
                .simultaneousGesture(
                    isDrawingMode || layer.isLocked ? nil : dragGesture
                )
                .simultaneousGesture(
                    isDrawingMode || layer.isLocked ? nil : pinchGesture
                )
                .simultaneousGesture(
                    isDrawingMode || layer.isLocked ? nil : rotationGesture
                )
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                onSelect()
                dragOffset = value.translation
            }
            .onEnded { value in
                layer.position.x += value.translation.width
                layer.position.y += value.translation.height
                dragOffset = .zero
            }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                onSelect()
                currentScale = scale
            }
            .onEnded { scale in
                layer.scale = max(0.2, min(5.0, layer.scale * scale))
                currentScale = 1.0
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { angle in
                onSelect()
                currentRotation = angle
            }
            .onEnded { angle in
                layer.rotation += angle
                currentRotation = .zero
            }
    }
}
