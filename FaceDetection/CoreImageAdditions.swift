//
//  CoreImageAdditions.swift
//  FaceDetection
//
//  Created by Ryan Davies on 27/03/2016.
//  Copyright © 2016 Ryan Davies. All rights reserved.
//

import AVFoundation
import CoreImage

extension CMSampleBuffer {
    var imageBuffer: CVImageBuffer? {
        get {
            return CMSampleBufferGetImageBuffer(self)
        }
    }
}

extension CIImage {
    convenience init?(CMSampleBuffer sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = sampleBuffer.imageBuffer else {
            return nil
        }
        self.init(cvPixelBuffer: imageBuffer)
    }
}

/*: CIFilter feels very Objective-C oriented, and there's no clear benefit to
 subclassing CIFilter over declaring our own protocol with the same signature.
 For new filters, conform to the `Filter` protocol instead of subclassing
 `CIFilter` unless necessary.
 */
protocol Filter {
    var inputImage: CIImage { get }
    var outputImage: CIImage? { get }
    
    init(inputImage: CIImage)
}

// This makes it easier to create filters from `CMSampleBuffer`.
extension Filter {
    init?(CMSampleBuffer sampleBuffer: CMSampleBuffer) {
        guard let image = CIImage(CMSampleBuffer: sampleBuffer) else {
            return nil
        }
        self.init(inputImage: image)
    }
}
