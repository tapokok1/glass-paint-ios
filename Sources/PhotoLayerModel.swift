import SwiftUI
import UIKit

struct PhotoLayer: Identifiable, Equatable {
    let id: UUID
    var title: String
    var originalImage: UIImage
    var displayImage: UIImage
    var position: CGPoint
    var scale: CGFloat
    var rotation: Angle
    var opacity: Double
    var isVisible: Bool
    var isLocked: Bool
    var hasCutout: Bool
    var adjustments: ImageAdjustments

    init(
        id: UUID = UUID(),
        title: String = "Слой Фото",
        image: UIImage,
        position: CGPoint = .zero,
        scale: CGFloat = 1.0,
        rotation: Angle = .zero,
        opacity: Double = 1.0,
        isVisible: Bool = true,
        isLocked: Bool = false,
        hasCutout: Bool = false,
        adjustments: ImageAdjustments = ImageAdjustments()
    ) {
        self.id = id
        self.title = title
        self.originalImage = image
        self.displayImage = image
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.opacity = opacity
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.hasCutout = hasCutout
        self.adjustments = adjustments
    }

    static func == (lhs: PhotoLayer, rhs: PhotoLayer) -> Bool {
        lhs.id == rhs.id &&
        lhs.position == rhs.position &&
        lhs.scale == rhs.scale &&
        lhs.rotation == rhs.rotation &&
        lhs.opacity == rhs.opacity &&
        lhs.isVisible == rhs.isVisible &&
        lhs.isLocked == rhs.isLocked &&
        lhs.hasCutout == rhs.hasCutout &&
        lhs.adjustments.brightness == rhs.adjustments.brightness &&
        lhs.adjustments.contrast == rhs.adjustments.contrast &&
        lhs.adjustments.saturation == rhs.adjustments.saturation &&
        lhs.adjustments.filter == rhs.adjustments.filter
    }
}
