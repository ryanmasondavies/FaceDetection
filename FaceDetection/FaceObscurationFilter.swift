//
//  FaceObscurationFilter.swift
//  FaceDetection
//
//  Created by Ryan Davies on 07/01/2016.
//  Copyright © 2016 Ryan Davies. All rights reserved.
//

import Foundation
import CoreImage

class FaceObscurationFilter: Filter {
    let inputImage: CIImage
    
    required init(inputImage: CIImage) {
        self.inputImage = inputImage
    }
    
    var outputImage: CIImage? {
        let startTime = Date()
        
        defer {
            let endTime = Date()
            let timeDelta = endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970
            print("Created output image in \(timeDelta) seconds.")
        }
        
        // Detect any faces in the image
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: nil,
                                  options: nil)
        
        guard let features = detector?.features(in: inputImage) else {
            print("Failed to read features from detector.")
            return inputImage
        }
        
        guard features.isEmpty == false else {
            // No features found
            // Nothing to pixellate - output image is the same as the input
            return inputImage
        }
        
        print("Features: \(features)")
        
        // Build a pixellated version of the image using the CIPixellate filter
        guard let pixellatedImage = PixellationFilter(inputImage: inputImage).outputImage else {
            // Failed to pixellate
            return nil
        }
        
        // Build a masking image for each of the faces
        var maskImage: CIImage?
        for feature in features {
            // Get feature position and radius for circle
            let xCenter = feature.bounds.origin.x + feature.bounds.size.width / 2.0
            let yCenter = feature.bounds.origin.y + feature.bounds.size.height / 2.0
            let radius = min(feature.bounds.size.width, feature.bounds.size.height) / 1.5
            
            // Input parameters for the circle filter
            var circleOptions: [String: AnyObject] = [:]
            circleOptions["inputRadius0"] = radius as AnyObject?
            circleOptions["inputRadius1"] = (radius + 1) as AnyObject
            circleOptions["inputColor0"] = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
            circleOptions["inputColor1"] = CIColor(red: 0, green: 0, blue: 0, alpha: 1)
            circleOptions[kCIInputCenterKey] = CIVector(x: xCenter, y: yCenter)
            
            // Create radial gradient circle at face position with face radius
            let radialGradient = CIFilter(name: "CIRadialGradient", withInputParameters: circleOptions)
            guard let circleImage = radialGradient?.outputImage else {
                // Something went wrong.
                // Try the next feature.
                continue
            }
            
            if maskImage == nil {
                maskImage = circleImage
            }
            
            guard let lastMaskImage = maskImage else {
                continue
            }
            
            // If the mask image is already set, create a composite of both the
            // new circle image and the old so we're creating one image with all
            // of the circles in it.
            let options: [String: AnyObject] = [kCIInputImageKey: circleImage, kCIInputBackgroundImageKey: lastMaskImage]
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
