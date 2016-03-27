//
//  CoreImageAdditions.swift
//  FaceDetection
//
//  Created by Ryan Davies on 27/03/2016.
//  Copyright © 2016 Ryan Davies. All rights reserved.
//

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
        self.init(CVPixelBuffer: imageBuffer)
    }
}
