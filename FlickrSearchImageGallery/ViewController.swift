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

class ViewController: UIViewController {

    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!

    @IBOutlet weak var flickrImageView1: UIImageView!
    @IBOutlet weak var flickrImageView2: UIImageView!
    @IBOutlet weak var flickrImageView3: UIImageView!
    @IBOutlet weak var flickrImageView4: UIImageView!

    @IBOutlet weak var flickrImageNameLabel1: UILabel!
    @IBOutlet weak var flickrImageNameLabel2: UILabel!
    @IBOutlet weak var flickrImageNameLabel3: UILabel!
    @IBOutlet weak var flickrImageNameLabel4: UILabel!

    @IBOutlet weak var keywordTextField: UITextField!

    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet var backgroundView: UIView!

    var allTextFields: [UITextField]!
    var recognizer: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.cancelButton.hidden = true
        self.cancelButton.userInteractionEnabled = false

        allTextFields = [keywordTextField]
        recognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleSingleTap))
        recognizer?.numberOfTapsRequired = 1 // Single tap
        backgroundView.addGestureRecognizer(recognizer) // Add gesture recognizer
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        self.activitySpinner.hidden = true
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        backgroundView.removeGestureRecognizer(recognizer)
        unsubscribeFromKeyboardNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func cancelKeywordSearch(sender: AnyObject) {
        
        FlickrAPI.sharedInstance.cancelKeywordSearch()
        
        dispatch_async(dispatch_get_main_queue(), {

            // TODO: Refactor into Helper method to achieve DRYer codebase

            self.cancelButton.hidden = true
            self.cancelButton.userInteractionEnabled = false
            self.searchButton.hidden = false
            self.searchButton.userInteractionEnabled = true

            self.activitySpinner.stopAnimating()
            self.activitySpinner.hidden = true
            
            self.notificationLabel.text = "Cancelled."
        })
    }
    
    @IBAction func searchByKeyword(sender: AnyObject) {
        
        self.notificationLabel.text = ""

        if keywordTextField.text != "" {

            FlickrAPI.sharedInstance.enableFlickrRequests()

            self.cancelButton.hidden = false
            self.cancelButton.userInteractionEnabled = true
            self.searchButton.hidden = true
            self.searchButton.userInteractionEnabled = false

            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "text": keywordTextField.text as! AnyObject,
                "nojsoncallback": NO_JSON_CALLBACK
            ]

            dismissAnyVisibleKeyboard() // Dismiss keyboard before search

            self.activitySpinner.hidden = false
            self.activitySpinner.startAnimating()

            FlickrAPI.sharedInstance.getImageFromFlickrBySearch(methodArguments)

            // Subscribe to a notification that fires upon Flickr Client response.
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.processFlickrResponse(_:)), name: FlickrClientProcessResponseNotification, object: nil)
        } else {

            dispatch_async(dispatch_get_main_queue(), {
                self.notificationLabel.text = "Error (input empty)."
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

            self.activitySpinner.stopAnimating()
            self.activitySpinner.hidden = true

            self.notificationLabel.text = response?["notification"] as? String

            // Only process responses where image exists
            if response!["image"] as! String != "" {

                /// Update Buttons
                self.cancelButton.hidden = true
                self.cancelButton.userInteractionEnabled = false
                self.searchButton.hidden = false
                self.searchButton.userInteractionEnabled = true
                
                /// Update Images in UI
                
                if let responseImage1 = response!["image"] {
                    // Update Image 1
                    if responseImage1 as! String != "" {
                        let imageURL1 = NSURL(string: responseImage1 as! String)
                        if let imageData1 = NSData(contentsOfURL: imageURL1!) {
                            self.flickrImageView1.image = UIImage(data: imageData1)
                        }
                    }
                }

                if let responseImage2 = response?["image2"] {
                    // Update Image 2
                    if responseImage2 as! String != "" {
                        let imageURL2 = NSURL(string: responseImage2 as! String)
                        if let imageData2 = NSData(contentsOfURL: imageURL2!) {
                            self.flickrImageView2.image = UIImage(data: imageData2)
                        }
                    }
                }

                if let responseImage3 = response?["image3"] {
                    // Update Image 3
                    if responseImage3 as! String != "" {
                        let imageURL3 = NSURL(string: responseImage3 as! String)
                        if let imageData3 = NSData(contentsOfURL: imageURL3!) {
                            self.flickrImageView3.image = UIImage(data: imageData3)
                        }
                    }
                }

                if let responseImage4 = response?["image4"] {
                    // Update Image 4
                    if responseImage4 as! String != "" {
                        let imageURL4 = NSURL(string: responseImage4 as! String)
                        if let imageData4 = NSData(contentsOfURL: imageURL4!) {
                            self.flickrImageView4.image = UIImage(data: imageData4)
                        }
                    }
                }
            }

            // Only process responses where image title exists
            if response!["imageTitle"] as! String != "" {

                /// Update Image Titles in UI

                if let responseImageTitle1 = response?["imageTitle"] {

                    // Update Image Title 1
                    if responseImageTitle1 as! String != "" {
                        self.flickrImageNameLabel1.text = responseImageTitle1 as? String
                    }
                }
                
                if let responseImageTitle2 = response?["imageTitle2"] {

                    // Update Image Title 2
                    if responseImageTitle2 as! String != "" {
                        self.flickrImageNameLabel2.text = responseImageTitle2 as? String
                    }
                }

                if let responseImageTitle3 = response?["imageTitle3"] {
                    // Update Image Title 3
                    if responseImageTitle3 as! String != "" {
                        self.flickrImageNameLabel3.text = responseImageTitle3 as? String
                    }
                }
                
                if let responseImageTitle4 = response?["imageTitle4"] {
                    // Update Image Title 4
                    if responseImageTitle4 as! String != "" {
                        self.flickrImageNameLabel4.text = responseImageTitle4 as? String
                    }
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

    // MARK: - Keyboard Event Subscriber Methods (UIKeyboard Pub/Sub Pattern)

    /**
     *  Selector Methods - Shift view when keyboard transitions in/out and covers text field
     */
    func keyboardWillShow(notification: NSNotification) {
        if keywordTextField.isFirstResponder() {
            backgroundView.frame.origin.y -= getKeyboardHeight(notification)
        }
    }

    func keyboardWillHide(notification: NSNotification) {
        if keywordTextField.isFirstResponder() {
            backgroundView.frame.origin.y += getKeyboardHeight(notification)
        }
    }

    /**
     *  Observer Methods - Observe for subscribe/unsubscribe event notifications to
     *                     show/hide keyboard by calling appropriate selector method
     */
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }

    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    // MARK: - Keyboard Public Methods
    
    /**
    *  Dismiss keyboard
    */
    func dismissKeyboard() {
        for textField in allTextFields {
            textField.resignFirstResponder()
        }
    }

    // MARK: - Keyboard Private Methods

    /**
     *  Obtain height of keyboard in view
     */
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        
        let userInfo = notification.userInfo // Dictionary
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }


    // MARK: - Segue

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        // Only transition to larger image view if the respective image has been loaded from Flickr
        switch identifier {
        case "ImageModalViewControllerID1":
            return self.flickrImageView1.image != nil ? true : false
        case "ImageModalViewControllerID2":
            return self.flickrImageView2.image != nil ? true : false
        case "ImageModalViewControllerID3":
            return self.flickrImageView3.image != nil ? true : false
        case "ImageModalViewControllerID4":
            return self.flickrImageView4.image != nil ? true : false
        default:
            return false
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        /**
        *  Forward the image stored in 'image' of flickrImageView properties
        *  to the ImageModalViewController's copyOfFlickrImage properties if not nil
        */

        if segue.identifier == "ImageModalViewControllerID1" {
            if let destinationVC = segue.destinationViewController as? ImageModalViewController {
                if self.flickrImageView1.image != nil {
                    destinationVC.copyOfFlickrImage1 = self.flickrImageView1.image
                    destinationVC.copyOfFlickrImageNameLabel1 = self.flickrImageNameLabel1.text
                    destinationVC.segueSenderID = segue.identifier!
                }
            }
        } else if segue.identifier == "ImageModalViewControllerID2" {
            if let destinationVC = segue.destinationViewController as? ImageModalViewController {
                if self.flickrImageView2.image != nil {
                    destinationVC.copyOfFlickrImage2 = self.flickrImageView2.image
                    destinationVC.copyOfFlickrImageNameLabel2 = self.flickrImageNameLabel2.text
                    destinationVC.segueSenderID = segue.identifier!
                }
            }
        } else if segue.identifier == "ImageModalViewControllerID3" {
            if let destinationVC = segue.destinationViewController as? ImageModalViewController {
                if self.flickrImageView3.image != nil {
                    destinationVC.copyOfFlickrImage3 = self.flickrImageView3.image
                    destinationVC.copyOfFlickrImageNameLabel3 = self.flickrImageNameLabel3.text
                    destinationVC.segueSenderID = segue.identifier!
                }
            }
        } else if segue.identifier == "ImageModalViewControllerID4" {
            if let destinationVC = segue.destinationViewController as? ImageModalViewController {
                if self.flickrImageView4.image != nil {
                    destinationVC.copyOfFlickrImage4 = self.flickrImageView4.image
                    destinationVC.copyOfFlickrImageNameLabel4 = self.flickrImageNameLabel4.text
                    destinationVC.segueSenderID = segue.identifier!
                }
            }
        }
        
    }
}
