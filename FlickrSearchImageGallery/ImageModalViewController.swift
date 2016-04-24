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

    var copyOfFlickrImageNameLabel1: String?
    var copyOfFlickrImageNameLabel2: String?
    var copyOfFlickrImageNameLabel3: String?
    var copyOfFlickrImageNameLabel4: String?
    
    var segueSenderID: String = ""

    @IBOutlet weak var imageModal: UIImageView!

    @IBOutlet weak var imageModalLabel: UILabel!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        switch segueSenderID {
            case "ImageModalViewControllerID1":
                self.imageModal.image = copyOfFlickrImage1
                self.imageModalLabel.text = copyOfFlickrImageNameLabel1
            case "ImageModalViewControllerID2":
                self.imageModal.image = copyOfFlickrImage2
                self.imageModalLabel.text = copyOfFlickrImageNameLabel2
            case "ImageModalViewControllerID3":
                self.imageModal.image = copyOfFlickrImage3
                self.imageModalLabel.text = copyOfFlickrImageNameLabel3
            case "ImageModalViewControllerID4":
                self.imageModal.image = copyOfFlickrImage4
                self.imageModalLabel.text = copyOfFlickrImageNameLabel4
            default:
                break
        }
    }

    @IBAction func closeModal(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}