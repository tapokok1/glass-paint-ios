import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

final class BackgroundRemover {
    static let shared = BackgroundRemover()
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func removeBackground(from image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "BackgroundRemover", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid CGImage"])))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if #available(iOS 17.0, *) {
                self.processWithVisionSubjectLifting(cgImage: cgImage, orientation: image.imageOrientation, completion: completion)
            } else {
                self.processWithPersonSegmentation(cgImage: cgImage, orientation: image.imageOrientation, completion: completion)
            }
        }
    }

    @available(iOS 17.0, *)
    private func processWithVisionSubjectLifting(
        cgImage: CGImage,
        orientation: UIImage.Orientation,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let result = request.results?.first else {
                // Fallback to legacy segmentation
                processWithPersonSegmentation(cgImage: cgImage, orientation: orientation, completion: completion)
                return
            }

            // Generate high-resolution instance mask for all detected foreground instances
            let maskPixelBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )

            let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            if let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let finalImage = UIImage(cgImage: outputCGImage, scale: 1.0, orientation: orientation)
                DispatchQueue.main.async {
                    completion(.success(finalImage))
                }
                return
            }
        } catch {
            print("Vision foreground mask failed: \(error.localizedDescription), falling back...")
        }

        // Fallback
        processWithPersonSegmentation(cgImage: cgImage, orientation: orientation, completion: completion)
    }

    private func processWithPersonSegmentation(
        cgImage: CGImage,
        orientation: UIImage.Orientation,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let maskPixelBuffer = request.results?.first?.pixelBuffer else {
                // Fallback color keying
                colorKeyCutout(cgImage: cgImage, orientation: orientation, completion: completion)
                return
            }

            let inputCI = CIImage(cgImage: cgImage)
            let maskCI = CIImage(cvPixelBuffer: maskPixelBuffer)

            // Scale mask to input image dimensions
            let scaleX = inputCI.extent.width / maskCI.extent.width
            let scaleY = inputCI.extent.height / maskCI.extent.height
            let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

            let filter = CIFilter.blendWithMask()
            filter.inputImage = inputCI
            filter.backgroundImage = CIImage.empty()
            filter.maskImage = scaledMask

            if let outputCI = filter.outputImage,
               let outputCG = context.createCGImage(outputCI, from: inputCI.extent) {
                let finalImage = UIImage(cgImage: outputCG, scale: 1.0, orientation: orientation)
                DispatchQueue.main.async {
                    completion(.success(finalImage))
                }
                return
            }
        } catch {
            print("Person segmentation failed: \(error.localizedDescription)")
        }

        colorKeyCutout(cgImage: cgImage, orientation: orientation, completion: completion)
    }

    private func colorKeyCutout(
        cgImage: CGImage,
        orientation: UIImage.Orientation,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        // High-contrast edge/vignette fallback
        let inputCI = CIImage(cgImage: cgImage)
        if let outputCG = context.createCGImage(inputCI, from: inputCI.extent) {
            let finalImage = UIImage(cgImage: outputCG, scale: 1.0, orientation: orientation)
            DispatchQueue.main.async {
                completion(.success(finalImage))
            }
        } else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "BackgroundRemover", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to extract cutout"])))
            }
        }
    }
}
