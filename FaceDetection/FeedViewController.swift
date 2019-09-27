//
//  ViewController.swift
//  FaceDetection
//
//  Created by Ryan Davies on 02/09/2014.
//  Copyright (c) 2016 Ryan Davies. All rights reserved.
//

import UIKit
import CoreImage

class FeedViewController: UIViewController {
    var feedView: FeedView {
        get {
            return self.view as! FeedView
        }
    }
    
    override func loadView() {
        self.view = FeedView()
    }
}
