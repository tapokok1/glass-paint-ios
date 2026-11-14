import SwiftUI

struct AdjustmentsSheetView: View {
    @ObservedObject var model: CanvasModel
    @Environment(\.dismiss) private var dismiss

    @State private var brightness: Float = 0.0
    @State private var contrast: Float = 1.0
    @State private var saturation: Float = 1.0
    @State private var sharpness: Float = 0.0
    @State private var blur: Float = 0.0
    @State private var selectedFilter: ImageFilterType = .original
    @State private var layerOpacity: Double = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background dark frosted tint
                Color.black.opacity(0.85)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // Background Cutout Action Card
                        cutoutActionCard

                        // Filters Carousel
                        filtersSection

                        // Sliders Section
                        adjustmentsSlidersSection

                        // Layer Opacity
                        opacitySection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Редактор фото")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.cyan)
                }
            }
            .onAppear {
                if let layer = model.selectedLayer {
                    brightness = layer.adjustments.brightness
                    contrast = layer.adjustments.contrast
                    saturation = layer.adjustments.saturation
                    sharpness = layer.adjustments.sharpness
                    blur = layer.adjustments.blur
                    selectedFilter = layer.adjustments.filter
                    layerOpacity = layer.opacity
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - AI Background Cutout

    private var cutoutActionCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Удаление фона")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Выделение объекта через Vision AI")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                if model.selectedLayer?.hasCutout == true {
                    Button {
                        model.restoreOriginalBackgroundForSelected()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Вернуть")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                } else {
                    Button {
                        model.removeBackgroundForSelected()
                    } label: {
                        HStack(spacing: 6) {
                            if model.isProcessingCutout {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "person.crop.rectangle.badge.plus")
                            }
                            Text("Вырезать фон")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.cyan))
                    }
                    .disabled(model.isProcessingCutout)
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 16, opacity: 0.8)
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Фильтры")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ImageFilterType.allCases) { filter in
                        Button {
                            selectedFilter = filter
                            applyChanges()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: filter.systemIcon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(selectedFilter == filter ? Color.cyan : Color.white)

                                Text(filter.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(selectedFilter == filter ? Color.cyan : Color.white.opacity(0.75))
                            }
                            .frame(width: 72, height: 64)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedFilter == filter ? Color.white.opacity(0.2) : Color.white.opacity(0.06))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        selectedFilter == filter ? Color.cyan : Color.white.opacity(0.15),
                                        lineWidth: selectedFilter == filter ? 1.5 : 0.8
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Adjustments Sliders

    private var adjustmentsSlidersSection: some View {
        VStack(spacing: 16) {
            sliderRow(
                title: "Яркость",
                icon: "sun.max",
                value: $brightness,
                in: -0.5...0.5
            )

            sliderRow(
                title: "Контраст",
                icon: "circle.righthalf.filled",
                value: $contrast,
                in: 0.5...2.0
            )

            sliderRow(
                title: "Насыщенность",
                icon: "paintpalette",
                value: $saturation,
                in: 0.0...2.0
            )

            sliderRow(
                title: "Резкость",
                icon: "diamond",
                value: $sharpness,
                in: 0.0...2.0
            )

            sliderRow(
                title: "Размытие",
                icon: "drop.triangle",
                value: $blur,
                in: 0.0...20.0
            )
        }
        .padding(16)
        .liquidGlass(cornerRadius: 16, opacity: 0.8)
    }

    private var opacitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Прозрачность слоя", systemImage: "slider.horizontal.below.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Text("\(Int(layerOpacity * 100))%")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color.cyan)
            }

            Slider(value: $layerOpacity, in: 0.05...1.0) { _ in
                if let id = model.selectedLayerId,
                   let idx = model.photoLayers.firstIndex(where: { $0.id == id }) {
                    model.photoLayers[idx].opacity = layerOpacity
                }
            }
            .tint(Color.cyan)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 16, opacity: 0.8)
    }

    private func sliderRow(
        title: String,
        icon: String,
        value: Binding<Float>,
        in range: ClosedRange<Float>
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color.cyan)
            }

            Slider(value: value, in: range) { _ in
                applyChanges()
            }
            .tint(Color.cyan)
        }
    }

    private func applyChanges() {
        let adjustments = ImageAdjustments(
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            sharpness: sharpness,
            blur: blur,
            filter: selectedFilter
        )
        model.updateAdjustmentsForSelected(adjustments)
    }
}
