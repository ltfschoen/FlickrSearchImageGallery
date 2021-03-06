//
//  ViewController.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 22/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import UIKit

/// Constants for JSON Endpoint (Private - API Key required)
let ENDPOINT_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search&"
let API_KEY = valueForAPIKey(named:"API_KEY_FLICKR")
let SAFE_SEARCH = "1"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

/// Constants for XML Endpoint (Public)
let ENDPOINT_URL_XML = "https://api.flickr.com/services/feeds/photos_public.gne"

class ViewController: UIViewController {

    var backgroundImageView = UIImageView(frame: UIScreen.mainScreen().bounds)

    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!

    @IBOutlet weak var flickrImageThumbView1: UIImageView!
    @IBOutlet weak var flickrImageThumbView2: UIImageView!
    @IBOutlet weak var flickrImageThumbView3: UIImageView!
    @IBOutlet weak var flickrImageThumbView4: UIImageView!

    var flickrImage1: UIImage?
    var flickrImage2: UIImage?
    var flickrImage3: UIImage?
    var flickrImage4: UIImage?

    @IBOutlet weak var flickrImageNameLabel1: UILabel!
    @IBOutlet weak var flickrImageNameLabel2: UILabel!
    @IBOutlet weak var flickrImageNameLabel3: UILabel!
    @IBOutlet weak var flickrImageNameLabel4: UILabel!

    @IBOutlet weak var keywordTextField: UITextField!

    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var xmlButton: UIButton!
    
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet var backgroundView: UIView!

    var allTextFields: [UITextField]!
    var recognizer: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.toggleOnCancelButton(false)

        allTextFields = [keywordTextField]
        recognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleSingleTap))
        recognizer?.numberOfTapsRequired = 1 // Single tap
        backgroundView.addGestureRecognizer(recognizer) // Add gesture recognizer
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set background image
        self.setBackgroundImage(self.interfaceOrientation)

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

    // Update to account for rotation when updating background image
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.setBackgroundImage(toInterfaceOrientation)
    }

    // Custom method to set the background image depending on device orientation
    func setBackgroundImage(orientation: UIInterfaceOrientation) {
        if (orientation == UIInterfaceOrientation.LandscapeLeft ||
            orientation == UIInterfaceOrientation.LandscapeRight) {
            print("Set background to landscape")

            UIGraphicsBeginImageContext(self.view.frame.size)
            let landscapeImage = UIImage(named: "background_image_landscape")
            landscapeImage!.drawInRect(self.view.bounds)
            let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.view.backgroundColor = UIColor(patternImage: image)

//            self.backgroundImageView.image = UIImage(named: "background_image_landscape")
//            self.view.insertSubview(backgroundImageView, atIndex: 0)
        }
        else {
            print("Set background to portrait")

            UIGraphicsBeginImageContext(self.view.frame.size)
            let portraitImage = UIImage(named: "background_image_portrait")
            portraitImage!.drawInRect(self.view.bounds)
            let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.view.backgroundColor = UIColor(patternImage: image)

//            self.backgroundImageView.image = UIImage(named: "background_image_portrait")
//            self.view.insertSubview(backgroundImageView, atIndex: 0)
        }
    }

    @IBAction func cancelKeywordSearch(sender: AnyObject) {
        
        FlickrAPI.sharedInstance.cancelKeywordSearch()
        
        dispatch_async(dispatch_get_main_queue(), {

            // TODO: Refactor into Helper method to achieve DRYer codebase

            self.toggleOnCancelButton(false)

            self.activitySpinner.stopAnimating()
            self.activitySpinner.hidden = true
            
            self.notificationLabel.text = "Cancelled."
        })
    }

    // XML Endpoint (no API key required)
    @IBAction func searchByKeywordXMLEndpoint(sender: AnyObject) {

        print("in searchByKeywordXMLEndpoint")
        
        self.notificationLabel.text = ""
        
        self.toggleOnXMLState(true)

        var methodArguments: NSDictionary = [:]

        // Allow empty input field, which signifies a non-tag filtering search
        if keywordTextField.text != "" {
            methodArguments = [
                "text": keywordTextField.text as! AnyObject
            ]
        } else {
            methodArguments = [
                "text": "" as AnyObject
            ]
        }
        
        dismissAnyVisibleKeyboard() // Dismiss keyboard before search
        
        self.activitySpinner.hidden = false
        self.activitySpinner.startAnimating()
        
        FlickrAPI.sharedInstance.getImageFromFlickrBySearchXMLEndpoint(methodArguments as! [String : AnyObject])
        
        // Subscribe to a notification that fires upon Flickr Client response.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.processFlickrXMLResponse(_:)), name: FlickrClientXMLProcessResponseNotification, object: nil)
    }

    // JSON Endpoint
    @IBAction func searchByKeyword(sender: AnyObject) {
        
        self.notificationLabel.text = ""

        if keywordTextField.text != "" {

            FlickrAPI.sharedInstance.enableFlickrRequests()

            self.toggleOnCancelButton(true)

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

    // MARK: - Button Helper Methods
    func toggleOnCancelButton(state: Bool) {
        if state == false {
            self.cancelButton.hidden = true
            self.cancelButton.userInteractionEnabled = false
            self.searchButton.hidden = false
            self.searchButton.userInteractionEnabled = true
            self.xmlButton.hidden = false
            self.xmlButton.userInteractionEnabled = true
        } else if state == true {
            self.cancelButton.hidden = false
            self.cancelButton.userInteractionEnabled = true
            self.searchButton.hidden = true
            self.searchButton.userInteractionEnabled = false
            self.xmlButton.hidden = true
            self.xmlButton.userInteractionEnabled = false
        }
    }

    func toggleOnXMLState(state: Bool) {
        if state == false {
            self.cancelButton.hidden = true
            self.cancelButton.userInteractionEnabled = false
            self.searchButton.hidden = false
            self.searchButton.userInteractionEnabled = true
            self.xmlButton.hidden = false
            self.xmlButton.userInteractionEnabled = true
        } else if state == true {
            self.cancelButton.hidden = false
            self.cancelButton.userInteractionEnabled = true
            self.searchButton.hidden = true
            self.searchButton.userInteractionEnabled = false
            self.xmlButton.hidden = true
            self.xmlButton.userInteractionEnabled = false
        }
    }

    // MARK: - API Response Methods

    /**
     *  Process notifications after Flickr Client XML query
     */
    func processFlickrXMLResponse(notification: NSNotification) {
        
        let response: [NSDictionary] = notification.object as! [NSDictionary]
        
        print("processFlickrXMLResponse with: \(response)")

        /// Update Buttons, Activity Spinner
        
        dispatch_async(dispatch_get_main_queue(), {
            self.activitySpinner.stopAnimating()
            self.activitySpinner.hidden = true
            self.toggleOnXMLState(false)
        })

        let imagesCount = response.count
        print("image dictionaries count is: \(imagesCount)")

        if imagesCount == 0 {
            
            self.notificationLabel.text = "Error: No images found. Try JSON or without tag(s)."

        } else if imagesCount != 0 {
            
            self.notificationLabel.text = "Success: Found \(imagesCount) images. Showing 4 random."

            /**
             *  Dispatch calls to obtain images from Flickr XML API response on background queue
             *  to keep UI responsive. Use the main queue to update the image view.
             */
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                /// Update Notification in UI
    //            dispatch_async(dispatch_get_main_queue(), {
    //                self.notificationLabel.text = response["notification"] as? String
    //            })

                // Generate Random indexes to get 4 random images from the array
                let randomImageIndex1 = Int(arc4random_uniform(UInt32(imagesCount-1))) + 1
                let randomImageIndex2 = Int(arc4random_uniform(UInt32(imagesCount-1))) + 1
                let randomImageIndex3 = Int(arc4random_uniform(UInt32(imagesCount-1))) + 1
                let randomImageIndex4 = Int(arc4random_uniform(UInt32(imagesCount-1))) + 1
                print("random indexes are: \(randomImageIndex1),\(randomImageIndex2),\(randomImageIndex3),\(randomImageIndex4)")
                    
                /// Update UI

                if response[randomImageIndex1]["title"] != nil {
                    self.flickrImageNameLabel1.text = response[randomImageIndex1]["title"] as? String
                }
                if response[randomImageIndex2]["title"] != nil {
                    self.flickrImageNameLabel2.text = response[randomImageIndex2]["title"] as? String
                }
                if response[randomImageIndex3]["title"] != nil {
                    self.flickrImageNameLabel3.text = response[randomImageIndex3]["title"] as? String
                }
                if response[randomImageIndex4]["title"] != nil {
                    self.flickrImageNameLabel4.text = response[randomImageIndex4]["title"] as? String
                }
                
//                // Thumbnails
//                if response[randomImageIndex1]["image_thumb"] != nil {
//                    let responseImageThumbURL1 = NSURL(string: response[randomImageIndex1]["image_thumb"] as! String)
//                    dispatch_async(dispatch_get_main_queue(), {
//                        if let responseImageThumbData1 = NSData(contentsOfURL: responseImageThumbURL1!) {
//                            self.flickrImageThumbView1.image = UIImage(data: responseImageThumbData1)
//                        }
//                    })
//                }
//                    
//                if response[randomImageIndex2]["image_thumb"] != nil {
//                    let responseImageThumbURL2 = NSURL(string: response[randomImageIndex2]["image_thumb"] as! String)
//                    dispatch_async(dispatch_get_main_queue(), {
//                        if let responseImageThumbData2 = NSData(contentsOfURL: responseImageThumbURL2!) {
//                            self.flickrImageThumbView2.image = UIImage(data: responseImageThumbData2)
//                        }
//                    })
//                }
//                
//                if response[randomImageIndex3]["image_thumb"] != nil {
//                    let responseImageThumbURL3 = NSURL(string: response[randomImageIndex3]["image_thumb"] as! String)
//                    dispatch_async(dispatch_get_main_queue(), {
//                        if let responseImageThumbData3 = NSData(contentsOfURL: responseImageThumbURL3!) {
//                            self.flickrImageThumbView3.image = UIImage(data: responseImageThumbData3)
//                        }
//                    })
//                }
//                
//                if response[randomImageIndex4]["image_thumb"] != nil {
//                    let responseImageThumbURL4 = NSURL(string: response[randomImageIndex4]["image_thumb"] as! String)
//                    dispatch_async(dispatch_get_main_queue(), {
//                        if let responseImageThumbData4 = NSData(contentsOfURL: responseImageThumbURL4!) {
//                            self.flickrImageThumbView4.image = UIImage(data: responseImageThumbData4)
//                        }
//                    })
//                }
                
                // Big images
                if response[randomImageIndex1]["image_big"] != nil {
                    let responseImageBigURL1 = NSURL(string: response[randomImageIndex1]["image_big"] as! String)
                    dispatch_async(dispatch_get_main_queue(), {
                        if let responseImageBigData1 = NSData(contentsOfURL: responseImageBigURL1!) {
                            self.flickrImage1 = UIImage(data: responseImageBigData1)
                            // Hack as thumbs are failing to display
                            self.flickrImageThumbView1.image = UIImage(data: responseImageBigData1)
                        }
                    })
                }
                
                if response[randomImageIndex2]["image_big"] != nil {
                    let responseImageBigURL2 = NSURL(string: response[randomImageIndex2]["image_big"] as! String)
                    dispatch_async(dispatch_get_main_queue(), {
                        if let responseImageBigData2 = NSData(contentsOfURL: responseImageBigURL2!) {
                            self.flickrImage2 = UIImage(data: responseImageBigData2)
                            // Hack as thumbs are failing to display
                            self.flickrImageThumbView2.image = UIImage(data: responseImageBigData2)
                        }
                    })
                }

                if response[randomImageIndex3]["image_big"] != nil {
                    let responseImageBigURL3 = NSURL(string: response[randomImageIndex3]["image_big"] as! String)
                    dispatch_async(dispatch_get_main_queue(), {
                        if let responseImageBigData3 = NSData(contentsOfURL: responseImageBigURL3!) {
                            self.flickrImage3 = UIImage(data: responseImageBigData3)
                            // Hack as thumbs are failing to display
                            self.flickrImageThumbView3.image = UIImage(data: responseImageBigData3)
                        }
                    })
                }

                if response[randomImageIndex4]["image_big"] != nil {
                    let responseImageBigURL4 = NSURL(string: response[randomImageIndex4]["image_big"] as! String)
                    dispatch_async(dispatch_get_main_queue(), {
                        if let responseImageBigData4 = NSData(contentsOfURL: responseImageBigURL4!) {
                            self.flickrImage4 = UIImage(data: responseImageBigData4)
                            // Hack as thumbs are failing to display
                            self.flickrImageThumbView4.image = UIImage(data: responseImageBigData4)
                        }
                    })
                }
            })
        }
    }
    
    /**
    *  Process notifications after Flickr Client query
    */
    func processFlickrResponse(notification: NSNotification) {

        let response = notification.object

        print("processFlickrResponse with: \(response)")

        /**
         *  Dispatch calls to obtain images from Flickr API response on a background queue
         *  to keep UI responsive. Use the main queue to update the image view.
         */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

            /// Update Notification in UI
            dispatch_async(dispatch_get_main_queue(), {
                self.notificationLabel.text = response?["notification"] as? String
            })
            
            // Only process responses where image exists
            if response!["image"] as! String != "" {

                /// Update Buttons, Activity Spinner

                dispatch_async(dispatch_get_main_queue(), {
                    self.activitySpinner.stopAnimating()
                    self.activitySpinner.hidden = true
                    self.toggleOnCancelButton(false)
                })
                
                /// Update Image Thumbnails in UI

                if let responseImageThumb1 = response!["imageThumb"] {
                    // Update Image Thumbnail 1
                    if responseImageThumb1 as! String != "" {
                        let imageThumbURL1 = NSURL(string: responseImageThumb1 as! String)
                        dispatch_async(dispatch_get_main_queue(), {
                            if let imageThumbData1 = NSData(contentsOfURL: imageThumbURL1!) {
                                self.flickrImageThumbView1.image = UIImage(data: imageThumbData1)
                            }
                        })
                    }
                }

                if let responseImageThumb2 = response!["imageThumb2"] {
                    // Update Image Thumbnail 2
                    if responseImageThumb2 as! String != "" {
                        let imageThumbURL2 = NSURL(string: responseImageThumb2 as! String)
                        dispatch_async(dispatch_get_main_queue(), {
                            if let imageThumbData2 = NSData(contentsOfURL: imageThumbURL2!) {
                                self.flickrImageThumbView2.image = UIImage(data: imageThumbData2)
                            }
                        })
                    }
                }

                if let responseImageThumb3 = response!["imageThumb3"] {
                    // Update Image Thumbnail 3
                    if responseImageThumb3 as! String != "" {
                        let imageThumbURL3 = NSURL(string: responseImageThumb3 as! String)
                        dispatch_async(dispatch_get_main_queue(), {
                            if let imageThumbData3 = NSData(contentsOfURL: imageThumbURL3!) {
                                self.flickrImageThumbView3.image = UIImage(data: imageThumbData3)
                            }
                        })
                    }
                }

                if let responseImageThumb4 = response!["imageThumb4"] {
                    // Update Image Thumbnail 4
                    if responseImageThumb4 as! String != "" {
                        let imageThumbURL4 = NSURL(string: responseImageThumb4 as! String)
                        dispatch_async(dispatch_get_main_queue(), {
                            if let imageThumbData4 = NSData(contentsOfURL: imageThumbURL4!) {
                                self.flickrImageThumbView4.image = UIImage(data: imageThumbData4)
                            }
                        })
                    }
                }
                
                /// Update Images in UI
                
                if let responseImage1 = response!["image"] {
                    // Update Image 1
                    if responseImage1 as! String != "" {
                        let imageURL1 = NSURL(string: responseImage1 as! String)
                        dispatch_async(dispatch_get_main_queue(), {
                            if let imageData1 = NSData(contentsOfURL: imageURL1!) {
                                self.flickrImage1 = UIImage(data: imageData1)!
                            }
                        })
                    }
                }

                if let responseImage2 = response?["image2"] {
                    // Update Image 2
                    if responseImage2 as! String != "" {
                        let imageURL2 = NSURL(string: responseImage2 as! String)
                        dispatch_async(dispatch_get_main_queue(), {
                            if let imageData2 = NSData(contentsOfURL: imageURL2!) {
                                self.flickrImage2 = UIImage(data: imageData2)!
                            }
                        })
                    }
                }

                if let responseImage3 = response?["image3"] {
                    // Update Image 3
                    if responseImage3 as! String != "" {
                        let imageURL3 = NSURL(string: responseImage3 as! String)
                        dispatch_async(dispatch_get_main_queue(), {
                            if let imageData3 = NSData(contentsOfURL: imageURL3!) {
                                self.flickrImage3 = UIImage(data: imageData3)!
                            }
                        })
                    }
                }

                if let responseImage4 = response?["image4"] {
                    // Update Image 4
                    if responseImage4 as! String != "" {
                        let imageURL4 = NSURL(string: responseImage4 as! String)
                        dispatch_async(dispatch_get_main_queue(), {
                            if let imageData4 = NSData(contentsOfURL: imageURL4!) {
                                self.flickrImage4 = UIImage(data: imageData4)!
                            }
                        })
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

    /**
     *  Double Tap to reveal Activity View for sharing image via multiple means including email
     */
    @IBAction func holdImage1(sender: AnyObject) {
        if let image1 = self.flickrImage1 {
            let activityVC = UIActivityViewController(activityItems: [image1] as [UIImage], applicationActivities: nil)
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }

    @IBAction func holdImage2(sender: AnyObject) {
        if let image2 = self.flickrImage2 {
            let activityVC = UIActivityViewController(activityItems: [image2] as [UIImage], applicationActivities: nil)
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }

    @IBAction func holdImage3(sender: AnyObject) {
        if let image3 = self.flickrImage3 {
            let activityVC = UIActivityViewController(activityItems: [image3] as [UIImage], applicationActivities: nil)
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }

    @IBAction func holdImage4(sender: AnyObject) {
        if let image4 = self.flickrImage4 {
            let activityVC = UIActivityViewController(activityItems: [image4] as [UIImage], applicationActivities: nil)
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
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
            return self.flickrImage1 != nil ? true : false
        case "ImageModalViewControllerID2":
            return self.flickrImage2 != nil ? true : false
        case "ImageModalViewControllerID3":
            return self.flickrImage3 != nil ? true : false
        case "ImageModalViewControllerID4":
            return self.flickrImage4 != nil ? true : false
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
                if self.flickrImage1 != nil {
                    destinationVC.copyOfFlickrImage1 = self.flickrImage1!
                    destinationVC.copyOfFlickrImageNameLabel1 = self.flickrImageNameLabel1.text
                    destinationVC.segueSenderID = segue.identifier!
                }
            }
        } else if segue.identifier == "ImageModalViewControllerID2" {
            if let destinationVC = segue.destinationViewController as? ImageModalViewController {
                if self.flickrImage2 != nil {
                    destinationVC.copyOfFlickrImage2 = self.flickrImage2!
                    destinationVC.copyOfFlickrImageNameLabel2 = self.flickrImageNameLabel2.text
                    destinationVC.segueSenderID = segue.identifier!
                }
            }
        } else if segue.identifier == "ImageModalViewControllerID3" {
            if let destinationVC = segue.destinationViewController as? ImageModalViewController {
                if self.flickrImage3 != nil {
                    destinationVC.copyOfFlickrImage3 = self.flickrImage3!
                    destinationVC.copyOfFlickrImageNameLabel3 = self.flickrImageNameLabel3.text
                    destinationVC.segueSenderID = segue.identifier!
                }
            }
        } else if segue.identifier == "ImageModalViewControllerID4" {
            if let destinationVC = segue.destinationViewController as? ImageModalViewController {
                if self.flickrImage4 != nil {
                    destinationVC.copyOfFlickrImage4 = self.flickrImage4!
                    destinationVC.copyOfFlickrImageNameLabel4 = self.flickrImageNameLabel4.text
                    destinationVC.segueSenderID = segue.identifier!
                }
            }
        }
        
    }
}
