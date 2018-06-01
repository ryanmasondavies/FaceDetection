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

private let SessionQueueLabel = "com.FaceDetection.camera.capture_session"
private let SampleBufferQueueLabel = "com.FaceDetection.camera.sample_buffer"

protocol CaptureSessionControllerDelegate {
    func captureSessionController(
        _ captureSessionController: CaptureSessionController,
        didStartRunningCaptureSession captureSession: AVCaptureSession
    )
    
    func captureSessionController(
        _ captureSessionController: CaptureSessionController,
        didStopRunningCaptureSession captureSession: AVCaptureSession
    )
    
    func captureSessionController(
        _ captureSessionController: CaptureSessionController,
        didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer
    )
    
    func captureSessionController(
        _ captureSessionController: CaptureSessionController,
        didFailWithError error: Error
    )
}

class CaptureSessionController: NSObject {
    // Use this queue for asynchronous calls to the capture session.
    fileprivate let sessionQueue = DispatchQueue(label: SessionQueueLabel, attributes: [])
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    fileprivate let outputQueue = DispatchQueue(label: SampleBufferQueueLabel, attributes: [])
    
    // Domain name for errors.
    static let errorDomain = "com.FaceDetection.CaptureSessionController.ErrorDomain"
    
    // Possible error types.
    enum Error : Swift.Error {
        case noCamera
        case failedToAddInput
        case failedToAddOutput
        case failedToSetVideoOrientation
    }
    
    let device: AVCaptureDevice? = {
        let devices = AVCaptureDevice.devices(for: .video)
        var camera: AVCaptureDevice? = nil
        for device in devices {
            if device.position == .front {
                camera = device
            }
        }
        return camera
    }()
    
    var input: AVCaptureDeviceInput? = nil
    var delegate: CaptureSessionControllerDelegate? = nil
    
    let captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        return session
    }()
    
    let videoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: Int(kCMPixelFormat_32BGRA) ]
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()
    
    fileprivate(set) var isSessionRunning = false {
        didSet {
            switch isSessionRunning {
            case true: self.delegate?.captureSessionController(self, didStartRunningCaptureSession: captureSession)
            case false: self.delegate?.captureSessionController(self, didStopRunningCaptureSession: captureSession)
            }
        }
    }
    
    fileprivate var isSessionConfigured = false
    
    func startCaptureSession() {
        if isSessionRunning { return }
        
        sessionQueue.async { [weak self] in
            // Do nothing if self has been deallocated.
            guard self != nil else { return }
            
            // Configure the capture session if it has not yet been configured.
            if let controller = self, !controller.isSessionConfigured {
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
        
        sessionQueue.async { [weak self] in
            guard self != nil else { return }
            self?.captureSession.stopRunning()
            self?.isSessionRunning = false
        }
    }
    
    fileprivate func configureCaptureSession() throws {
        guard let device = device else {
            throw Error.noCamera
        }
        
        // Grab the input for this device.
        let input = try AVCaptureDeviceInput(device: device)
        
        // Assign our input, to remember it for future use.
        self.input = input
        
        // Set the sample buffer delegate of the video data output to self
        videoDataOutput.setSampleBufferDelegate(self, queue: outputQueue)
        
        // Begin configuring the session...
        captureSession.beginConfiguration()
        
        // Add input if possible.
        guard captureSession.canAddInput(input) == true else {
            throw Error.failedToAddInput
        }
        captureSession.addInput(input)
        
        // Add the video data output to the capture session if possible
        guard captureSession.canAddOutput(videoDataOutput) == true else {
            throw Error.failedToAddOutput
        }
        captureSession.addOutput(videoDataOutput)
        
        // Assign a device orientation to the video data output.
        guard let connection = videoDataOutput.connection(with: .video) else {
            throw Error.failedToSetVideoOrientation
        }
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
        // Finish configuring the session.
        captureSession.commitConfiguration()
        
        // That's it. Configured.
        isSessionConfigured = true
    }
}

extension CaptureSessionController : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ captureOutput: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
        ) {
            delegate?.captureSessionController(self, didUpdateWithSampleBuffer: sampleBuffer)
    }
}
