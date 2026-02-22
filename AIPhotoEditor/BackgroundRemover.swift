//
//  BackgroundRemover.swift
//  AIPhotoEditor
//
//  Created by Preeti Chauhan on 2/20/26.
//

import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum BackgroundType {
    case transparent
    case color(UIColor)
    case photo(UIImage)
}

class BackgroundRemover {

    /// Step 1 — Run Vision person segmentation and return the normalized CGImage + mask.
    static func computeMask(from image: UIImage,
                            completion: @escaping (CGImage?, CVPixelBuffer?) -> Void) {
        let normalized = image.normalizedOrientation()
        guard let cgImage = normalized.cgImage else {
            completion(nil, nil)
            return
        }

        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                guard let result = request.results?.first else {
                    DispatchQueue.main.async { completion(nil, nil) }
                    return
                }
                DispatchQueue.main.async { completion(cgImage, result.pixelBuffer) }
            } catch {
                DispatchQueue.main.async { completion(nil, nil) }
            }
        }
    }

    /// Step 2 — Composite the person onto the chosen background using the saved mask.
    static func applyBackground(_ background: BackgroundType,
                                mask: CVPixelBuffer,
                                to cgImage: CGImage) -> UIImage? {
        let scaleX = CGFloat(cgImage.width) / CGFloat(CVPixelBufferGetWidth(mask))
        let scaleY = CGFloat(cgImage.height) / CGFloat(CVPixelBufferGetHeight(mask))
        let maskCI = CIImage(cvPixelBuffer: mask)
            .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let imageCI = CIImage(cgImage: cgImage)

        let backgroundCI: CIImage
        switch background {
        case .transparent:
            backgroundCI = CIImage.empty()
        case .color(let uiColor):
            backgroundCI = CIImage(color: CIColor(color: uiColor))
                .cropped(to: imageCI.extent)
        case .photo(let bgImage):
            let normalizedBG = bgImage.normalizedOrientation()
            guard let bgCG = normalizedBG.cgImage else { return nil }
            backgroundCI = CIImage(cgImage: bgCG).transformed(by: CGAffineTransform(
                scaleX: CGFloat(cgImage.width) / CGFloat(bgCG.width),
                y: CGFloat(cgImage.height) / CGFloat(bgCG.height)
            ))
        }

        let filter = CIFilter.blendWithMask()
        filter.inputImage = imageCI
        filter.maskImage = maskCI
        filter.backgroundImage = backgroundCI

        let context = CIContext()
        guard let output = filter.outputImage,
              let cgResult = context.createCGImage(output, from: imageCI.extent) else {
            return nil
        }

        return UIImage(cgImage: cgResult)
    }
}

extension UIImage {
    /// Returns a copy of the image with orientation normalised to .up.
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
