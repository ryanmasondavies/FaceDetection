//
//  PixellationFilter.swift
//  FaceDetection
//
//  Created by Ryan Davies on 27/03/2016.
//  Copyright © 2016 Ryan Davies. All rights reserved.
//

import Foundation
import CoreImage

struct PixellationFilter : Filter {
    let inputImage: CIImage
    var inputFactor: CGFloat
    var inputCenter: CIVector
    
    init(inputImage: CIImage) {
        self.inputImage = inputImage
        self.inputFactor = 20
        
        let inputImageSize = inputImage.extent.size
        self.inputCenter = CIVector(
            x: inputImageSize.width / 2,
            y: inputImageSize.height / 2
        )
    }
    
    var outputImage: CIImage? {
        let inputImageSize = inputImage.extent.size
        let inputScale = max(inputImageSize.width, inputImageSize.height) / inputFactor
        return inputImage.applyingFilter(
            "CIPixellate",
            withInputParameters: [
                kCIInputScaleKey: inputScale,
                kCIInputCenterKey: inputCenter
            ]
        )
    }
}
