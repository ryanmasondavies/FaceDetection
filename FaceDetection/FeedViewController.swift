//
//  ViewController.swift
//  FaceDetection
//
//  Created by Ryan Davies on 02/09/2014.
//  Copyright (c) 2016 Ryan Davies. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation

class FeedViewController: UIViewController {
    lazy var captureSessionController: CaptureSessionController = {
        let controller = CaptureSessionController()
        controller.delegate = self
        return controller
    }()
    
    var imageView: UIImageView {
        get {
            return self.view as! UIImageView
        }
    }
    
    override func loadView() {
        self.view = UIImageView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        captureSessionController.startCaptureSession()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        captureSessionController.stopCaptureSession()
    }
}

extension FeedViewController : CaptureSessionControllerDelegate {
    func captureSessionController(captureSessionController: CaptureSessionController, didStartRunningCaptureSession captureSession: AVCaptureSession) {
        print("Capture session started.")
    }
    
    func captureSessionController(captureSessionController: CaptureSessionController, didStopRunningCaptureSession captureSession: AVCaptureSession) {
        print("Capture session stopped.")
    }
    
    func captureSessionController(captureSessionController: CaptureSessionController, didFailWithError error: ErrorType) {
        print("Failed with error: \(error)")
    }
    
    func captureSessionController(captureSessionController: CaptureSessionController, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer) {
        if let filter = PixellationFilter(CMSampleBuffer: sampleBuffer) {
            dispatch_async(dispatch_get_main_queue()) {
                let image = filter.outputImage ?? filter.inputImage
                self.imageView.image = UIImage(CIImage: image)
            }
        }
    }
}
