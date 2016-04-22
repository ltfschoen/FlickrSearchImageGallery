//
//  ViewController.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 22/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import UIKit

// Constants
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
            "text" : keywordTextField.text as! AnyObject,
            "nojsoncallback": NO_JSON_CALLBACK
        ]

        dismissAnyVisibleKeyboard() // Dismiss keyboard before search
        getImageFromFlickrBySearch(methodArguments)
    }

    // MARK: - Helper Methods

    /**
     *  Convert given dictionary of parameters (methodArguments) to a string for url
     */
    func escapedParameters(parameters: [String : AnyObject]) -> String {

        var urlVars = [String]()

        for (key, value) in parameters {

            // Convert to string value
            let stringValue = "\(value)"
            
            // Escape given string
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

            // Append escaped string
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    // MARK: - API Search Methods

    /**
    *  Request random page from Flickr API. Call separate method to get image from random page
    */
    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject]) {
        print("getImageFromFlickrBySearch with: \(methodArguments)")

        let session = NSURLSession.sharedSession()
        let urlString = ENDPOINT_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Error (no API response): \(error)")
                dispatch_async(dispatch_get_main_queue(), {
                    self.notificationLabel.text = "Error (no API response). Try again."
                    // self.imageNameLabel.alpha = 1.0
                    self.flickrImageView.image = nil
                })
            } else {

                var parsingError: NSError? = nil
                let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary

                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {

                    if let totalPages = photosDictionary["pages"] as? Int {

                        /**
                        *  Note: Flickr API allows up to 4000 images when queries are
                        *  paginated by temporal range or bounding box to limit queries
                        *  in the response.
                        *
                        *  Here we restrict the total pages to a max of 40 and selecting a
                        *  random page, which may have around 100 images.
                        */

                        let pageLimit = min(totalPages, 40)
                        print("page limit is: \(pageLimit)")
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        print("randomPage is: \(randomPage)")
                        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)

                    } else {
                        print("Error (API). Missing key 'pages' in \(photosDictionary)")
                        dispatch_async(dispatch_get_main_queue(), {
                            self.notificationLabel.text = "Error (API). Contact developer."
                            // self.imageNameLabel.alpha = 1.0
                            self.flickrImageView.image = nil
                        })
                    }
                } else {
                    print("Error (API). Missing key 'photos' in \(parsedResult)")
                    dispatch_async(dispatch_get_main_queue(), {
                        self.notificationLabel.text = "Error (API). Contact developer."
                        // self.imageNameLabel.alpha = 1.0
                        self.flickrImageView.image = nil
                    })
                }
            }
        }
        task.resume()
    }

    /**
     *  Request to obtain a Flickr image using the random page passed as a parameter
     */
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {

        // Add page parameter to methodArguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber

        let session = NSURLSession.sharedSession()
        let urlString = ENDPOINT_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Error (no API response): \(error)")
                dispatch_async(dispatch_get_main_queue(), {
                    self.notificationLabel.text = "Error (no API response). Try again."
                    // self.imageNameLabel.alpha = 1.0
                    self.flickrImageView.image = nil
                })
            } else {
                var parsingError: NSError? = nil
                let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary

                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {

                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }

                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            print("photosArray is: \(photosArray)")
                            print("photosArray Count is: \(photosArray.count)")

                            if photosArray.count > 0 {
                                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                                print("randomPhotoIndex is: \(randomPhotoIndex)")
                                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                                print("photoDictionary is: \(photoDictionary)")

                                let photoTitle = photoDictionary["title"] as? String
                                let imageUrlString = photoDictionary["url_m"] as? String
                                let imageURL = NSURL(string: imageUrlString!)

                                if let imageData = NSData(contentsOfURL: imageURL!) {
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.notificationLabel.text = "Success. Found image."
                                        // self.imageNameLabel.alpha = 0.0
                                        self.flickrImageView.image = UIImage(data: imageData)
                                        self.imageNameLabel.text = "\(photoTitle!)"
                                    })
                                } else {
                                    print("Error (no image in response) at \(imageURL)")
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.notificationLabel.text = "Error (no image in response). Try again."
                                        // self.imageNameLabel.alpha = 1.0
                                        self.flickrImageView.image = nil
                                    })
                                }
                            } else {
                                print("Error (no image in response) only an empty array")
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.notificationLabel.text = "Error (no image in response). Try again."
                                    // self.imageNameLabel.alpha = 1.0
                                    self.flickrImageView.image = nil
                                })
                            }
                        } else {
                            print("Error (API). Missing key 'photo' in \(photosDictionary)")
                            dispatch_async(dispatch_get_main_queue(), {
                                self.notificationLabel.text = "Error (API). Contact developer."
                                // self.imageNameLabel.alpha = 1.0
                                self.flickrImageView.image = nil
                            })
                        }
                    } else {
                        print("Error (API). No photos found using key 'total'")
                        dispatch_async(dispatch_get_main_queue(), {
                            self.imageNameLabel.text = "Error (no photo in response). Try again."
                            // self.imageNameLabel.alpha = 1.0
                            self.flickrImageView.image = nil
                        })
                    }
                } else {
                    print("Error (API). Missing key 'photos' in \(parsedResult)")
                    dispatch_async(dispatch_get_main_queue(), {
                        self.notificationLabel.text = "Error (API). Contact developer."
                        // self.imageNameLabel.alpha = 1.0
                        self.flickrImageView.image = nil
                    })
                }
            }
        }

        task.resume()
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

    // MARK: - Keyboard Private Methods

    /**
    *  Dismiss keyboard
    */
    private func dismissKeyboard() {
        for textField in allTextFields {
            textField.resignFirstResponder()
        }
    }

    /**
     *  Obtain height of keyboard in view
     */
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        
        let userInfo = notification.userInfo // Dictionary
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
}

// MARK: - Extensions Methods for View Controller

/**
 * Dismiss any visible keyboard
 */
extension ViewController {
    func dismissAnyVisibleKeyboard() {
        dismissKeyboard()
    }
}
