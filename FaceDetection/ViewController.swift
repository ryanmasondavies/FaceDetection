//
//  ViewController.swift
//  FaceDetection
//
//  Created by Ryan Davies on 02/09/2014.
//  Copyright (c) 2014 Ryan Davies. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation

protocol VideoFeedDelegate {
    func videoFeed(videoFeed: VideoFeed, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer!)
}

class VideoFeed: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    let outputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)
    
    let device: AVCaptureDevice? = {
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as [AVCaptureDevice]
        var camera: AVCaptureDevice? = nil
        for device in devices {
            if device.position == .Front {
                camera = device
            }
        }
        return camera
    }()
    
    var input: AVCaptureDeviceInput? = nil
    var delegate: VideoFeedDelegate? = nil
    
    let session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        return session
    }()
    
    let videoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: kCMPixelFormat_32BGRA ]
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()
    
    func start(error: NSErrorPointer) -> Bool {
        if configure(error) {
            session.startRunning()
            return true
        }
        return false
    }
    
    func stop() {
        session.stopRunning()
    }
    
    private func configure(error: NSErrorPointer) -> Bool {
        if let maybeInput: AnyObject = AVCaptureDeviceInput.deviceInputWithDevice(device!, error: error) {
            input = maybeInput as? AVCaptureDeviceInput
            if session.canAddInput(input) {
                session.addInput(input)
                videoDataOutput.setSampleBufferDelegate(self, queue: outputQueue);
                if session.canAddOutput(videoDataOutput) {
                    session.addOutput(videoDataOutput)
                    let connection = videoDataOutput.connectionWithMediaType(AVMediaTypeVideo)
                    connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                    return true
                } else {
                    println("Video output error.");
                }
            } else {
                println("Video input error. Maybe unauthorised or no camera.")
            }
        } else {
            println("Failed to start capturing video with error: \(error)")
        }
        return false
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        // Update the delegate
        if delegate != nil {
            delegate!.videoFeed(self, didUpdateWithSampleBuffer: sampleBuffer)
        }
    }
}

class FaceObscurationFilter {
    let inputImage: CIImage
    var outputImage: CIImage? = nil
    
    init(inputImage: CIImage) {
        self.inputImage = inputImage
    }
    
    convenience init(sampleBuffer: CMSampleBuffer) {
        // Create a CIImage from the buffer
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = CIImage(CVPixelBuffer: imageBuffer)
        
        self.init(inputImage: image)
    }
    
    func process() {
        // Detect any faces in the image
        let detector = CIDetector(ofType: CIDetectorTypeFace, context:nil, options:nil)
        let features = detector.featuresInImage(inputImage)
        
        println("Features: \(features)")
        
        // Build a pixellated version of the image using the CIPixellate filter
        let imageSize = inputImage.extent().size
        let pixellationOptions = [kCIInputScaleKey: max(imageSize.width, imageSize.height) / 10]
        let pixellation = CIFilter(name: "CIPixellate", withInputParameters: pixellationOptions)
        let pixellatedImage = pixellation.outputImage
        
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
            let circleImage = radialGradient.outputImage
            
            if maskImage != nil {
                // If the mask image is already set, create a composite of both the
                // new circle image and the old so we're creating one image with all
                // of the circles in it.
                let options = [kCIInputImageKey: circleImage, kCIInputBackgroundImageKey: maskImage]
                let composition = CIFilter(name: "CISourceOverCompositing", withInputParameters: options)
                maskImage = composition.outputImage
            } else {
                // If it's not set, remember it for composition next time.
                maskImage = circleImage;
            }
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
        let blend = CIFilter(name: "CIBlendWithMask", withInputParameters: blendOptions)
        
        // Finally, set the resulting image as the output
        outputImage = blend.outputImage
    }
}

class ViewController: UIViewController, VideoFeedDelegate {
    @IBOutlet weak var imageView: UIImageView!
    let feed: VideoFeed = VideoFeed()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        feed.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        startVideoFeed()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        feed.stop()
    }
    
    func startVideoFeed() {
        var maybeError: NSError?
        if (feed.start(&maybeError)) {
            println("Video started.")
        } else {
            // alert?
            // need to look into device permissions
        }
    }
    
    func videoFeed(videoFeed: VideoFeed, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer!) {
        let filter = FaceObscurationFilter(sampleBuffer: sampleBuffer)
        filter.process()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.imageView.image = UIImage(CIImage: filter.outputImage)
        })
    }
}
