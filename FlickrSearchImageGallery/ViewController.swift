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
        subscribeToKeyboardNotifications()
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

    @IBAction func searchByKeyword(sender: AnyObject) {

        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "text": keywordTextField.text as! AnyObject,
            "nojsoncallback": NO_JSON_CALLBACK
        ]

        dismissAnyVisibleKeyboard() // Dismiss keyboard before search

        FlickrAPI.sharedInstance.getImageFromFlickrBySearch(methodArguments)

        // Subscribe to a notification that fires upon Flickr Client response.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processFlickrResponse:", name: FlickrClientProcessResponseNotification, object: nil)
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
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
}
