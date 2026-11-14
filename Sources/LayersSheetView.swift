import SwiftUI

struct LayersSheetView: View {
    @ObservedObject var model: CanvasModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Header Actions
                    HStack {
                        Text("Слои холста")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)

                        Spacer()

                        Text("\(model.photoLayers.count + 1) слоёв")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    List {
                        // Section 1: Vector Drawing Layer (Top)
                        Section {
                            HStack(spacing: 12) {
                                Image(systemName: "pencil.tip.crop.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(Color.cyan)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Слой рисования")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Text("PencilKit штрихи")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.6))
                                }

                                Spacer()

                                Button {
                                    model.isDrawingMode = true
                                    model.selectedLayerId = nil
                                    dismiss()
                                } label: {
                                    Text(model.isDrawingMode ? "Активен" : "Выбрать")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(model.isDrawingMode ? Color.cyan : Color.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.white.opacity(0.12)))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(model.isDrawingMode ? Color.cyan.opacity(0.15) : Color.white.opacity(0.06))
                            )
                        }

                        // Section 2: Photo Layers
                        if !model.photoLayers.isEmpty {
                            Section(header: Text("Фото-слои").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.5))) {
                                ForEach(model.photoLayers.reversed()) { layer in
                                    photoLayerRow(layer: layer)
                                }
                            }
                        }

                        // Section 3: Background Layer
                        Section(header: Text("Фоновый слой").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.5))) {
                            HStack(spacing: 12) {
                                Image(systemName: model.backgroundStyle.systemIcon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.white)

                                Text("Фон холста: \(model.backgroundStyle.rawValue)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)

                                Spacer()

                                Menu {
                                    ForEach(CanvasBackgroundStyle.allCases) { style in
                                        Button {
                                            model.backgroundStyle = style
                                        } label: {
                                            Label(style.rawValue, systemImage: style.systemIcon)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.cyan)
                                        .padding(8)
                                        .background(Circle().fill(Color.white.opacity(0.1)))
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Панель слоёв")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.cyan)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func photoLayerRow(layer: PhotoLayer) -> some View {
        let isSelected = model.selectedLayerId == layer.id && !model.isDrawingMode

        return HStack(spacing: 12) {
            // Thumbnail
            Image(uiImage: layer.displayImage)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(layer.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Text("\(Int(layer.opacity * 100))%")
                        .font(.system(size: 10).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))

                    if layer.hasCutout {
                        Text("Вырезан")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.cyan)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.cyan.opacity(0.2)))
                    }
                }
            }

            Spacer()

            // Eye Visibility Toggle
            Button {
                model.toggleLayerVisibility(id: layer.id)
            } label: {
                Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                    .font(.system(size: 15))
                    .foregroundStyle(layer.isVisible ? Color.white : Color.white.opacity(0.3))
            }
            .buttonStyle(.plain)

            // Lock Toggle
            Button {
                model.toggleLayerLock(id: layer.id)
            } label: {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 14))
                    .foregroundStyle(layer.isLocked ? Color.yellow : Color.white.opacity(0.4))
            }
            .buttonStyle(.plain)

            // Select
            Button {
                model.selectedLayerId = layer.id
                model.isDrawingMode = false
                dismiss()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(isSelected ? Color.cyan : Color.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.cyan.opacity(0.18) : Color.white.opacity(0.06))
        )
    }
}
