import UIKit
import CoreImage

func pixellate(inputImage: CIImage) -> CIImage? {
    let imageSize = inputImage.extent.size
    let pixellationOptions = [
        kCIInputImageKey: inputImage,
        kCIInputCenterKey: CIVector(x: imageSize.width / 2, y: imageSize.height / 2),
        kCIInputScaleKey: max(imageSize.width, imageSize.height) / 20,
    ]
    let pixellation = CIFilter(name: "CIPixellate", withInputParameters: pixellationOptions)
    
    guard let pixellatedImage = pixellation?.outputImage else {
        return nil
    }
    
    return pixellatedImage
}

let monaLisaURL = NSBundle.mainBundle().URLForResource("monalisa", withExtension: "jpg")
let image = CIImage(contentsOfURL: monaLisaURL!)

pixellate(image!)
