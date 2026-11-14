import SwiftUI

// MARK: - Liquid Glass Modifiers & Styles

struct LiquidGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.65
    var borderWidth: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base blur material
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(opacity)

                    // Liquid tint gradient
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.04),
                                    Color.cyan.opacity(0.05),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Specular glass border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.65),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: borderWidth
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
            .shadow(color: Color.cyan.opacity(0.08), radius: 24, x: 0, y: 4)
    }
}

struct LiquidGlassPill: ViewModifier {
    var isSelected: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(Color.white.opacity(0.22)) : AnyShapeStyle(.ultraThinMaterial))
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected
                                ? [Color.white.opacity(0.9), Color.cyan.opacity(0.6)]
                                : [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            }
            .shadow(color: isSelected ? Color.cyan.opacity(0.35) : Color.clear, radius: 8)
    }
}

struct GlassIconButton: View {
    let systemName: String
    var title: String? = nil
    var isSelected: Bool = false
    var tint: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.cyan : tint)

                if let title = title {
                    Text(title)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(isSelected ? Color.cyan : Color.white.opacity(0.75))
                }
            }
            .frame(width: 44, height: 44)
            .background {
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected
                                ? [Color.cyan.opacity(0.9), Color.white.opacity(0.6)]
                                : [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.5 : 0.75
                    )
            }
            .shadow(color: isSelected ? Color.cyan.opacity(0.4) : Color.clear, radius: 6)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, opacity: Double = 0.7, borderWidth: CGFloat = 1.0) -> some View {
        modifier(LiquidGlassBackground(cornerRadius: cornerRadius, opacity: opacity, borderWidth: borderWidth))
    }

    func liquidGlassPill(isSelected: Bool = false) -> some View {
        modifier(LiquidGlassPill(isSelected: isSelected))
    }
}
