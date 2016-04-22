//
//  ViewController.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 22/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import UIKit

/// Constants
let ENDPOINT_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search&"
let API_KEY = valueForAPIKey(named:"API_KEY_FLICKR")
let SAFE_SEARCH = "1"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

class ViewController: UICollectionViewController {

    var collectionImages: [String] = []

    // MARK: - Collection View Constants
    private let reuseIdentifier = "Cell"

    @IBOutlet var collectionImageView: UICollectionView!

    @IBOutlet weak var flickrImageView: UIImageView!
    @IBOutlet weak var keywordTextField: UITextField!
    @IBOutlet weak var imageNameLabel: UILabel!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet var backgroundView: UIView!

    var allTextFields: [UITextField]!
    var recognizer: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        allTextFields = [keywordTextField]
        recognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap")
        recognizer?.numberOfTapsRequired = 1 // Single tap
        backgroundView.addGestureRecognizer(recognizer) // Add gesture recognizer
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        backgroundView.removeGestureRecognizer(recognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func searchByKeyword(sender: AnyObject) {

        if keywordTextField.text != "" {
            
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "text": keywordTextField.text as! AnyObject,
                "nojsoncallback": NO_JSON_CALLBACK
            ]

            FlickrAPI.sharedInstance.getImageFromFlickrBySearch(methodArguments)

            // Subscribe to a notification that fires upon Flickr Client response.
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "processFlickrResponse:", name: FlickrClientProcessResponseNotification, object: nil)
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.notificationLabel.text = "Error (input field empty)"
            })
        }
    }

    // MARK: - API Response Methods

    /**
    *  Process notifications after Flickr Client query
    */
    func processFlickrResponse(notification: NSNotification) {

        let response = notification.object

        print("processFlickrResponse with: \(response)")

        dispatch_async(dispatch_get_main_queue(), {

            self.notificationLabel.text = response?["notification"] as? String

            if let responseImage = response?["image"] {
                if responseImage as! String != "" {
                    let imageURL = NSURL(string: responseImage as! String)

                    if let imageData = NSData(contentsOfURL: imageURL!) {
                        self.flickrImageView.image = UIImage(data: imageData)
                    }
                }
            }
            if let responseImageTitle = response?["imageTitle"] {
                if responseImageTitle as! String != "" {
                    self.imageNameLabel.text = responseImageTitle as? String
                }
            }
        })
    }
    
    // MARK: - Gesture Methods

    /**
     *  Dismiss keyboard when tap outside textfield
     */
    func handleSingleTap() {
        backgroundView.endEditing(true)
    }

}
