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

class BackgroundRemover {
    static func removeBackground(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
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
                    completion(nil)
                    return
                }

                let maskedImage = applyMask(mask: result.pixelBuffer, to: cgImage)
                DispatchQueue.main.async {
                    completion(maskedImage)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    private static func applyMask(mask: CVPixelBuffer, to image: CGImage) -> UIImage? {
        let maskCI = CIImage(cvPixelBuffer: mask)
            .applyingFilter("CIBicubicScaleTransform", parameters: [
                "inputScale": CGFloat(image.width) / CGFloat(CVPixelBufferGetWidth(mask))
            ])

        let imageCI = CIImage(cgImage: image)

        let filter = CIFilter.blendWithMask()
        filter.inputImage = imageCI
        filter.maskImage = maskCI
        filter.backgroundImage = CIImage.empty()

        let context = CIContext()
        guard let output = filter.outputImage,
              let cgResult = context.createCGImage(output, from: imageCI.extent) else {
            return nil
        }

        return UIImage(cgImage: cgResult)
    }
}

