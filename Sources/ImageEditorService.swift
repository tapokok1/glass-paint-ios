import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum ImageFilterType: String, CaseIterable, Identifiable {
    case original = "Оригинал"
    case mono = "Моно"
    case noir = "Нуар"
    case sepia = "Сепия"
    case vivid = "Яркий"
    case chrome = "Хром"
    case instant = "Винтаж"
    case invert = "Негатив"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .original: return "circle"
        case .mono: return "circle.lefthalf.filled"
        case .noir: return "circle.fill"
        case .sepia: return "sun.max"
        case .vivid: return "sparkles"
        case .chrome: return "camera.filters"
        case .instant: return "photo.artframe"
        case .invert: return "arrow.left.arrow.right.circle"
        }
    }
}

struct ImageAdjustments {
    var brightness: Float = 0.0      // -0.5 to 0.5
    var contrast: Float = 1.0        // 0.5 to 2.0
    var saturation: Float = 1.0      // 0.0 to 2.0
    var sharpness: Float = 0.0       // 0.0 to 2.0
    var blur: Float = 0.0            // 0.0 to 20.0
    var filter: ImageFilterType = .original
}

final class ImageEditorService {
    static let shared = ImageEditorService()
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func applyAdjustments(to image: UIImage, adjustments: ImageAdjustments) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        var ciImage = CIImage(cgImage: cgImage)

        // 1. Color Controls (Brightness, Contrast, Saturation)
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = ciImage
        colorControls.brightness = adjustments.brightness
        colorControls.contrast = adjustments.contrast
        colorControls.saturation = adjustments.saturation
        if let output = colorControls.outputImage {
            ciImage = output
        }

        // 2. Sharpness
        if adjustments.sharpness > 0.01 {
            let sharpen = CIFilter.sharpenLuminance()
            sharpen.inputImage = ciImage
            sharpen.sharpness = adjustments.sharpness
            if let output = sharpen.outputImage {
                ciImage = output
            }
        }

        // 3. Blur
        if adjustments.blur > 0.01 {
            let blurFilter = CIFilter.gaussianBlur()
            blurFilter.inputImage = ciImage
            blurFilter.radius = adjustments.blur
            if let output = blurFilter.outputImage {
                ciImage = output.clampedToExtent().cropped(to: ciImage.extent)
            }
        }

        // 4. Creative Filter
        ciImage = applyFilter(adjustments.filter, to: ciImage)

        // Render back to UIImage
        if let renderedCG = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: renderedCG, scale: image.scale, orientation: image.imageOrientation)
        }
        return image
    }

    private func applyFilter(_ filter: ImageFilterType, to ciImage: CIImage) -> CIImage {
        switch filter {
        case .original:
            return ciImage
        case .mono:
            let f = CIFilter.photoEffectMono()
            f.inputImage = ciImage
            return f.outputImage ?? ciImage
        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = ciImage
            return f.outputImage ?? ciImage
        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = ciImage
            f.intensity = 0.85
            return f.outputImage ?? ciImage
        case .vivid:
            let f = CIFilter.photoEffectChrome()
            f.inputImage = ciImage
            return f.outputImage ?? ciImage
        case .chrome:
            let f = CIFilter.colorPosterize()
            f.inputImage = ciImage
            f.levels = 8
            return f.outputImage ?? ciImage
        case .instant:
            let f = CIFilter.photoEffectInstant()
            f.inputImage = ciImage
            return f.outputImage ?? ciImage
        case .invert:
            let f = CIFilter.colorInvert()
            f.inputImage = ciImage
            return f.outputImage ?? ciImage
        }
    }
}
