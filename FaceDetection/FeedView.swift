//
//  FeedView.swift
//  FaceDetection
//
//  Created by Ryan Davies on 27/09/2019.
//  Copyright © 2019 Ryan Davies. All rights reserved.
//

import UIKit
import AVFoundation

class FeedView: UIView, CameraFeedDelegate {
    lazy var cameraFeed: CameraFeed = {
        let feed = CameraFeed()
        feed.delegate = self
        return feed
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        NSLayoutConstraint.activate([
            leftAnchor.constraint(equalTo: imageView.leftAnchor),
            rightAnchor.constraint(equalTo: imageView.rightAnchor),
            topAnchor.constraint(equalTo: imageView.topAnchor),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func didMoveToSuperview() {
        guard superview != nil else {
            cameraFeed.stopCaptureSession()
            return
        }
        cameraFeed.startCaptureSession()
    }

    func cameraFeed(_ cameraFeed: CameraFeed, didStartRunningCaptureSession captureSession: AVCaptureSession) {
        print("Capture session started.")
    }

    func cameraFeed(_ cameraFeed: CameraFeed, didStopRunningCaptureSession captureSession: AVCaptureSession) {
        print("Capture session stopped.")
    }

    func cameraFeed(_ cameraFeed: CameraFeed, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer) {
        guard let filter = FaceObscurationFilter(CMSampleBuffer: sampleBuffer) else {
            return
        }
        DispatchQueue.main.async {
            let image = filter.outputImage ?? filter.inputImage
            self.imageView.image = UIImage(ciImage: image)
        }
    }

    func cameraFeed(_ cameraFeed: CameraFeed, didFailWithError error: Error) {
        print("Failed with error: \(error)")
    }
}
