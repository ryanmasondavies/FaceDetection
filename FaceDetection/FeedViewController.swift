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
    let feed = VideoFeed()
    
    var imageView: UIImageView {
        get {
            return self.view as! UIImageView
        }
    }
    
    override func loadView() {
        self.view = UIImageView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        do {
            try feed.start()
            print("Video started.")
            return
        } catch {
            // alert?
            // need to look into device permissions
        }
    }
}

extension FeedViewController : VideoFeedDelegate {
    func videoFeed(videoFeed: VideoFeed, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer!) {
        let filter = FaceObscurationFilter(sampleBuffer: sampleBuffer)
        filter.process()
        dispatch_async(dispatch_get_main_queue()) {
            let image = filter.outputImage ?? filter.inputImage
            self.imageView.image = UIImage(CIImage: image)
        }
    }
}
