import UIKit
import CoreImage

func pixellate(image image: CIImage) -> CIImage? {
    let imageSize = image.extent.size
    let options: [String: Any] = [
        kCIInputCenterKey: CIVector(x: imageSize.width / 2, y: imageSize.height / 2),
        kCIInputScaleKey: max(imageSize.width, imageSize.height) / 20,
    ]
    return image.applyingFilter("CIPixellate", withInputParameters: options)
}

let monaLisaURL = Bundle.main.url(forResource: "monalisa", withExtension: "jpg")
let monaLisa = CIImage(contentsOf: monaLisaURL!)

pixellate(image: monaLisa!)
