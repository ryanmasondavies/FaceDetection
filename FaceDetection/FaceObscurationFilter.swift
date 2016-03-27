//
//  FaceObscurationFilter.swift
//  FaceDetection
//
//  Created by Ryan Davies on 07/01/2016.
//  Copyright © 2016 Ryan Davies. All rights reserved.
//

import Foundation
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
        self.init(CVPixelBuffer: imageBuffer)
    }
}

protocol Filter {
    var inputImage: CIImage { get }
    var outputImage: CIImage? { get }
    
    init(inputImage: CIImage)
}

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
        return inputImage.imageByApplyingFilter(
            "CIPixellate",
            withInputParameters: [
                kCIInputScaleKey: inputScale,
                kCIInputCenterKey: inputCenter
            ]
        )
    }
}

class FaceObscurationFilter : CIFilter {
    let inputImage: CIImage
    
    init(inputImage: CIImage) {
        self.inputImage = inputImage
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        // Detect any faces in the image
        let detector = CIDetector(ofType: CIDetectorTypeFace, context:nil, options:nil)
        let features = detector.featuresInImage(inputImage)
        guard features.count > 0 else {
            // No features found
            // Nothing to pixellate - output image is the same as the input
            return inputImage
        }
        
        print("Features: \(features)")
        
        // Build a pixellated version of the image using the CIPixellate filter
        let imageSize = inputImage.extent.size
        let pixellationOptions = [
            kCIInputScaleKey: max(imageSize.width, imageSize.height) / 10,
            kCIInputCenterKey: CIVector(x: imageSize.width / 2, y: imageSize.height / 2)
        ]
        let pixellation = CIFilter(name: "CIPixellate", withInputParameters: pixellationOptions)
        guard let pixellatedImage = pixellation?.outputImage else {
            // Failed to pixellate
            return nil
        }
        
        // Build a masking image for each of the faces
        var maskImage: CIImage? = nil
        for feature in features {
            // Get feature position and radius for circle
            let xCenter = feature.bounds.origin.x + feature.bounds.size.width / 2.0
            let yCenter = feature.bounds.origin.y + feature.bounds.size.height / 2.0
            let radius = min(feature.bounds.size.width, feature.bounds.size.height) / 1.5
            
            // Input parameters for the circle filter
            var circleOptions: [String: AnyObject] = [:]
            circleOptions["inputRadius0"] = radius
            circleOptions["inputRadius1"] = radius + 1
            circleOptions["inputColor0"] = CIColor(red: 0, green: 1, blue: 0, alpha: 1)
            circleOptions["inputColor1"] = CIColor(red: 0, green: 0, blue: 0, alpha: 1)
            circleOptions[kCIInputCenterKey] = CIVector(x: xCenter, y: yCenter)
            
            // Create radial gradient circle at face position with face radius
            let radialGradient = CIFilter(name: "CIRadialGradient", withInputParameters: circleOptions)
            guard let circleImage = radialGradient?.outputImage else {
                // Something went wrong.
                // Try the next feature.
                continue
            }
            
            guard let image = maskImage else {
                // Mask image is not set - so remember it for composition next time.
                maskImage = circleImage
                continue
            }
            
            // If the mask image is already set, create a composite of both the
            // new circle image and the old so we're creating one image with all
            // of the circles in it.
            let options: [String: AnyObject] = [kCIInputImageKey: circleImage, kCIInputBackgroundImageKey: image]
            let composition = CIFilter(name: "CISourceOverCompositing", withInputParameters: options)!
            maskImage = composition.outputImage
        }
        
        // Create a single blended image made up of the pixellated image, the mask image, and the original image.
        // We want sections of the pixellated image to be removed according to the mask image, to reveal
        // the original image in the background.
        // We use the CIBlendWithMask filter for this, and set the background image as the original image,
        // the input image (the one to be masked) as the pixellated image, and the mask image as, well, the mask.
        var blendOptions: [String: AnyObject] = [:]
        blendOptions[kCIInputImageKey] = pixellatedImage
        blendOptions[kCIInputBackgroundImageKey] = inputImage
        blendOptions[kCIInputMaskImageKey] = maskImage
        
        guard let blend = CIFilter(name: "CIBlendWithMask", withInputParameters: blendOptions) else {
            return nil
        }
        
        // Finally, set the resulting image as the output
        return blend.outputImage
    }
}

extension FaceObscurationFilter {
    convenience init?(CMSampleBuffer sampleBuffer: CMSampleBuffer) {
        guard let image = CIImage(CMSampleBuffer: sampleBuffer) else {
            return nil
        }
        self.init(inputImage: image)
    }
}
