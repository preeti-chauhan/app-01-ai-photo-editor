//
//  FilterManager.swift
//  AIPhotoEditor
//
//  Created by Preeti Chauhan on 2/20/26.
//

import Foundation
import CoreImage
import UIKit

struct PhotoFilter {
    let name: String
    let filter: (CIImage) -> CIImage?
}

class FilterManager {
    static let filters: [PhotoFilter] = [
        PhotoFilter(name: "Original") { image in
            return image
        },
        PhotoFilter(name: "Vivid") { image in
            return image.applyingFilter("CIVibrance", parameters: ["inputAmount": 1.0])
        },
        PhotoFilter(name: "Mono") { image in
            return image.applyingFilter("CIPhotoEffectMono")
        },
        PhotoFilter(name: "Fade") { image in
            return image.applyingFilter("CIPhotoEffectFade")
        },
        PhotoFilter(name: "Chrome") { image in
            return image.applyingFilter("CIPhotoEffectChrome")
        },
        PhotoFilter(name: "Noir") { image in
            return image.applyingFilter("CIPhotoEffectNoir")
        },
        PhotoFilter(name: "Warm") { image in
            return image.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 4000, y: 0),
                "inputTargetNeutral": CIVector(x: 6500, y: 0)
            ])
        },
        PhotoFilter(name: "Cool") { image in
            return image.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 8000, y: 0),
                "inputTargetNeutral": CIVector(x: 6500, y: 0)
            ])
        }
    ]

    static func apply(filter: PhotoFilter, to image: UIImage) -> UIImage? {
        let fixedImage = image.fixedOrientation() // add this line
        guard let cgImage = fixedImage.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)

        guard let outputCI = filter.filter(ciImage) else { return nil }

        let context = CIContext()
        guard let outputCG = context.createCGImage(outputCI, from: outputCI.extent) else { return nil }

        return UIImage(cgImage: outputCG)
    }
}

extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}
