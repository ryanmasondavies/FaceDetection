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
        do {
            try feed.start()
            print("Video started.")
            return
        } catch {
            // alert?
            // need to look into device permissions
        }
    }
    
    func videoFeed(videoFeed: VideoFeed, didUpdateWithSampleBuffer sampleBuffer: CMSampleBuffer!) {
        let filter = FaceObscurationFilter(sampleBuffer: sampleBuffer)
        filter.process()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.imageView.image = UIImage(CIImage: filter.outputImage!)
        })
    }
}
