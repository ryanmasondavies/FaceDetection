//
//  VideoFeed.swift
//  FaceDetection
//
//  Created by Ryan Davies on 07/01/2016.
//  Copyright © 2016 Ryan Davies. All rights reserved.
//

import Foundation
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
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
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
        output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: Int(kCMPixelFormat_32BGRA) ]
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()
    
    func start() throws {
        try configure()
        session.startRunning()
    }
    
    func stop() {
        session.stopRunning()
    }
    
    private func configure() throws {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        do {
            let maybeInput: AnyObject = try AVCaptureDeviceInput(device: device!)
            input = maybeInput as? AVCaptureDeviceInput
            if session.canAddInput(input) {
                session.addInput(input)
                videoDataOutput.setSampleBufferDelegate(self, queue: outputQueue);
                if session.canAddOutput(videoDataOutput) {
                    session.addOutput(videoDataOutput)
                    let connection = videoDataOutput.connectionWithMediaType(AVMediaTypeVideo)
                    connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                    return
                } else {
                    print("Video output error.");
                }
            } else {
                print("Video input error. Maybe unauthorised or no camera.")
            }
        } catch let error1 as NSError {
            error = error1
            print("Failed to start capturing video with error: \(error)")
        }
        throw error
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        // Update the delegate
        if delegate != nil {
            delegate!.videoFeed(self, didUpdateWithSampleBuffer: sampleBuffer)
        }
    }
}
