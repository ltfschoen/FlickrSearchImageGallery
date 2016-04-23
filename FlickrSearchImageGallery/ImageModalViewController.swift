//
//  ImageModalViewController.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 23/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import UIKit

class ImageModalViewController: UIViewController {

    var copyOfFlickrImage1: UIImage?
    var copyOfFlickrImage2: UIImage?
    var copyOfFlickrImage3: UIImage?
    var copyOfFlickrImage4: UIImage?
    var segueSenderID: String = ""

    @IBOutlet weak var imageModal: UIImageView!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        switch segueSenderID {
            case "ImageModalViewControllerID1":
                self.imageModal.image = copyOfFlickrImage1
            case "ImageModalViewControllerID2":
                self.imageModal.image = copyOfFlickrImage2
            case "ImageModalViewControllerID3":
                self.imageModal.image = copyOfFlickrImage3
            case "ImageModalViewControllerID4":
                self.imageModal.image = copyOfFlickrImage4
            default:
                break
        }
    }

    @IBAction func closeModal(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}