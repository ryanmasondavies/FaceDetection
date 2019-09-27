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
    lazy var cameraFeed: CameraFeed = {
        let controller = CameraFeed()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraFeed.startCaptureSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraFeed.stopCaptureSession()
    }
}

extension FeedViewController : CameraFeedDelegate {
    func cameraFeed(_ cameraFeed: CameraFeed, didStartRunningCaptureSession captureSession: AVCaptureSession) {
        print("Capture session started.")
    }
    
    func cameraFeed(_ cameraFeed: CameraFeed, didStopRunningCaptureSession captureSession: AVCaptureSession) {
        print("Capture session stopped.")
    }
    
    func cameraFeed(_ cameraFeed: CameraFeed, didFailWithError error: Error) {
        print("Failed with error: \(error)")
    }
    
    func cameraFeed(_ cameraFeed: CameraFeed, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer) {
        if let filter = FaceObscurationFilter(CMSampleBuffer: sampleBuffer) {
            DispatchQueue.main.async {
                let image = filter.outputImage ?? filter.inputImage
                self.imageView.image = UIImage(ciImage: image)
            }
        }
    }
}
