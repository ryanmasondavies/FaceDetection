//
//  CaptureSessionController.swift
//  FaceDetection
//
//  Created by Ryan Davies on 07/01/2016.
//  Copyright © 2016 Ryan Davies. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation

private let SessionQueueLabel = "com.ryandavies.camera.capture_session"
private let SampleBufferQueueLabel = "com.ryandavies.camera.sample_buffer"

protocol CaptureSessionControllerDelegate {
    func captureSessionController(
        captureSessionController: CaptureSessionController,
        didStartRunningCaptureSession captureSession: AVCaptureSession
    )
    
    func captureSessionController(
        captureSessionController: CaptureSessionController,
        didStopRunningCaptureSession captureSession: AVCaptureSession
    )
    
    func captureSessionController(
        captureSessionController: CaptureSessionController,
        didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer
    )
    
    func captureSessionController(
        captureSessionController: CaptureSessionController,
        didFailWithError error: ErrorType
    )
}

class CaptureSessionController: NSObject {
    // Use this queue for asynchronous calls to the capture session.
    private let sessionQueue = dispatch_queue_create(SessionQueueLabel, DISPATCH_QUEUE_SERIAL)
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    private let outputQueue = dispatch_queue_create(SampleBufferQueueLabel, DISPATCH_QUEUE_SERIAL)
    
    // Domain name for errors.
    static let errorDomain = "com.ryandavies.CaptureSessionController.ErrorDomain"
    
    // Possible error types.
    enum Error : ErrorType {
        case FailedToAddInput
        case FailedToAddOutput
        case FailedToSetVideoOrientation
    }
    
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
    var delegate: CaptureSessionControllerDelegate? = nil
    
    let captureSession: AVCaptureSession = {
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
    
    private(set) var isSessionRunning = false {
        didSet {
            switch isSessionRunning {
            case true: self.delegate?.captureSessionController(self, didStartRunningCaptureSession: captureSession)
            case false: self.delegate?.captureSessionController(self, didStopRunningCaptureSession: captureSession)
            }
        }
    }
    
    private var isSessionConfigured = false
    
    func startCaptureSession() {
        if isSessionRunning { return }
        
        dispatch_async(sessionQueue) { [weak self] in
            // Do nothing if self has been deallocated.
            guard self != nil else { return }
            
            // Configure the capture session if it has not yet been configured.
            if let controller = self where !controller.isSessionConfigured {
                do {
                    try controller.configureCaptureSession()
                }
                catch {
                    controller.delegate?.captureSessionController(controller, didFailWithError: error)
                }
            }
            
            // Start the session!
            self?.captureSession.startRunning()
            self?.isSessionRunning = true
        }
    }
    
    func stopCaptureSession() {
        if !isSessionRunning { return }
        
        dispatch_async(sessionQueue) { [weak self] in
            guard self != nil else { return }
            self?.captureSession.stopRunning()
            self?.isSessionRunning = false
        }
    }
    
    private func configureCaptureSession() throws {
        // Grab the input for this device.
        guard let input: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: device) else { return }
        
        // Assign our input, to remember it for future use.
        self.input = input
        
        // Set the sample buffer delegate of the video data output to self
        videoDataOutput.setSampleBufferDelegate(self, queue: outputQueue)
        
        // Begin configuring the session...
        captureSession.beginConfiguration()
        
        // Add input if possible.
        guard captureSession.canAddInput(input) == true else {
            throw Error.FailedToAddInput
        }
        captureSession.addInput(input)
        
        // Add the video data output to the capture session if possible
        guard captureSession.canAddOutput(videoDataOutput) == true else {
            throw Error.FailedToAddOutput
        }
        captureSession.addOutput(videoDataOutput)
        
        // Assign a device orientation to the video data output.
        guard let connection = videoDataOutput.connectionWithMediaType(AVMediaTypeVideo) else {
            throw Error.FailedToSetVideoOrientation
        }
        connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        
        // Finish configuring the session.
        captureSession.commitConfiguration()
        
        // That's it. Configured.
        isSessionConfigured = true
    }
}

extension CaptureSessionController : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        captureOutput: AVCaptureOutput!,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
        fromConnection connection: AVCaptureConnection!
        ) {
            delegate?.captureSessionController(self, didUpdateWithSampleBuffer: sampleBuffer)
    }
}
