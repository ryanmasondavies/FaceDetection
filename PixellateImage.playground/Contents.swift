import UIKit
import CoreImage

func pixellate(image image: CIImage) -> CIImage? {
    let imageSize = image.extent.size
    let options = [
        kCIInputCenterKey: CIVector(x: imageSize.width / 2, y: imageSize.height / 2),
        kCIInputScaleKey: max(imageSize.width, imageSize.height) / 20,
    ]
    return image.imageByApplyingFilter("CIPixellate", withInputParameters: options)
}

let monaLisaURL = NSBundle.mainBundle().URLForResource("monalisa", withExtension: "jpg")
let monaLisa = CIImage(contentsOfURL: monaLisaURL!)

pixellate(image: monaLisa!)
