//
//  FlickrClient.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 22/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import Foundation

/// Notification generated when a product is purchased.
public let FlickrClientProcessResponseNotification = "FlickrClientProcessResponseNotification"

/**
 *  Flickr Client class to perform communication with Flickr API
 */
class FlickrClient: NSObject {
    
    // MARK: Properties

    var cancelFlickrRequests: Bool = false

    var flickrTask: NSURLSessionDataTask?
    var flickrTaskWithPage: NSURLSessionDataTask?

    var processResponse: [String: AnyObject]?

    var flickrRequestTimer: NSTimer? // Timer for method that requests random page from Flickr API
    var flickrRequestWithPageTimer: NSTimer? // Timer for method requesting image from random page
    var pageLimit: Int? // Store page limit of current Flickr request for new page no. on retry
    var randomPage: Int? // Store random page since on retry we want to avoid retrying the same
    var randomPageRetryHistory: [Int] = []
    
    var imageUrlString1: String?
    var imageUrlString2: String?
    var imageUrlString3: String?
    var imageUrlString4: String?
    
    var photoTitle1: String?
    var photoTitle2: String?
    var photoTitle3: String?
    var photoTitle4: String?

    // MARK: Initialisation

    override init() {
        super.init()
    }

    // MARK: - API Search Helper Methods

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

    // TODO: Refactor into Helper methods to achieve DRYer codebase

    /**
     *  Configure NSTimer to call Flickr request method each specified time interval
     *  until timer terminated
     */
    func processRetryRequest(methodArguments: [String : AnyObject]) {
        print("----- processRetryRequest -----")

        // Automatically add timer to run loop so it starts firing
        self.flickrRequestTimer = NSTimer(timeInterval: 3, target: self, selector: Selector("readyToRetryFlickrBySearch:"), userInfo: ["key1" : methodArguments], repeats: false)
        NSRunLoop.mainRunLoop().addTimer(self.flickrRequestTimer!, forMode:NSRunLoopCommonModes)
    }

    func readyToRetryFlickrBySearch(timer: NSTimer?) {
        print("----- readyToRetryFlickrBySearch -----  \(timer!.userInfo)")
        getImageFromFlickrBySearch(timer?.userInfo?["key1"] as! [String : AnyObject])
    }

    /**
     *  Delegate method of NSURLSession receives callback when activity completes.
     *  Important: Ensure that correct request task variable name is used.
     *
     */
    func URLSession(session: NSURLSession, flickrTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        print("----- URLSession -----")

        /*
         *  Invalidate timer stored as property of the request object and calls a method
         *  on the object) when finished with it to break the strong reference cycle.
         */
        if self.flickrRequestTimer != nil {
            self.flickrRequestTimer!.invalidate()
        }
    }
    
    /**
     *  Configure NSTimer to call Flickr request (with page) method each specified time interval
     *  until timer terminated
     */
    func processRetryRequestWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {
        
        print("----- processRetryRequestWithPage -----")
        
        /// Generate a new random page number (unique not previously used) for the retry request

        var foundUnique = false
        var newRandomPageGenerated: Int?

        // Only keep trying until we exhaust the page limit (source of random number) itself
        while foundUnique == false {

            newRandomPageGenerated = Int(arc4random_uniform(UInt32(self.pageLimit!))) + 1

            func checkForDuplicateInRandomPageHistory(rpg: Int) -> Bool {
                let count = self.randomPageRetryHistory.count
                for var index = 0; index < count; index += 1 {
                    if self.randomPageRetryHistory[index] == rpg {
                        return true
                    }
                }
                return false
            }
            if checkForDuplicateInRandomPageHistory(newRandomPageGenerated!) == false {
                foundUnique = true
            }
        }
        self.randomPage = newRandomPageGenerated!
        
        // Cast randomPage as an Int for use in the NSTimer dictionary
        let randomPageAsIntForDictionary = self.randomPage! as Int

        // Automatically add timer to run loop so it starts firing
        self.flickrRequestWithPageTimer = NSTimer(timeInterval: 5, target: self, selector: #selector(readyToRetryFlickrBySearchWithPage), userInfo: ["key1" : methodArguments, "key2" : randomPageAsIntForDictionary], repeats: false)
        NSRunLoop.mainRunLoop().addTimer(self.flickrRequestWithPageTimer!, forMode:NSRunLoopCommonModes)
    }

    func readyToRetryFlickrBySearchWithPage(timer: NSTimer?) {
        print("----- readyToRetryFlickrBySearchWithPage ----- \(timer!.userInfo)")
        getImageFromFlickrBySearchWithPage(timer?.userInfo?["key1"] as! [String : AnyObject], pageNumber: timer?.userInfo?["key2"] as! Int)
    }
    
    // TODO: Remove URLSession methods. No benefit as not hooking into self.flickrTask__
    
    /**
     *  Delegate method of NSURLSession receives callback when activity completes.
     *  Important: Ensure that correct request task variable name is used.
     *
     */
    func URLSession(session: NSURLSession, flickrTaskWithPage: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        print("----- URLSession (with Page) -----")

        /*
         *  Invalidate timer stored as property of the request object and calls a method
         *  on the object) when finished with it to break the strong reference cycle.
         */
        if self.flickrRequestWithPageTimer != nil {
            self.flickrRequestWithPageTimer!.invalidate()
        }
    }
    
    /**
    *  Request random page from Flickr API. Call separate method to
    *  get image from random page
    */
    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject]) {
        print("----- getImageFromFlickrBySearch with: \(methodArguments)")

        // TODO: Consider benefits of using a Background Session
        let session = NSURLSession.sharedSession()
        let urlString = ENDPOINT_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        self.flickrTask = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Error (no API response): \(error). Auto-retrying.")
                if self.cancelFlickrRequests == false {
                    self.processResponse = [
                        "notification": "Error (no API response). Auto-retrying." as AnyObject,
                        "image": "",
                        "imageTitle": ""
                    ]
                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                    self.processRetryRequest(methodArguments)
                }
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
                        
                        self.pageLimit = min(totalPages, 40)
                        print("page limit is: \(self.pageLimit)")
                        self.randomPage = Int(arc4random_uniform(UInt32(self.pageLimit!))) + 1

                        // Add this random page to search history to prevent retrying same page
                        self.randomPageRetryHistory.append(self.randomPage!)
                        print("randomPage is: \(self.randomPage)")
                        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: self.randomPage!)
                        if self.flickrRequestTimer != nil {
                            self.flickrRequestTimer!.invalidate()
                        }
                        
                    } else {
                        print("Error (API). Missing key 'pages' in \(photosDictionary)")
                        if self.cancelFlickrRequests == false {
                            self.processResponse = [
                                "notification": "Error (API)." as AnyObject,
                                "image": "",
                                "imageTitle": ""
                            ]
                            NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                        }
                    }
                } else {
                    print("Error (API). Missing key 'photos' in \(parsedResult)")
                    if self.cancelFlickrRequests == false {
                        self.processResponse = [
                            "notification": "Error (API)." as AnyObject,
                            "image": "",
                            "imageTitle": ""
                        ]
                        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                    }
                }
            }
        }
        self.flickrTask!.resume()
    }
    
    /**
     *  Request to obtain a Flickr image using the random page passed as a parameter
     */
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {
        
        // Add page parameter to methodArguments
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = ENDPOINT_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        self.flickrTaskWithPage = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Error (no API response): \(error). Auto-retrying.")
                if self.cancelFlickrRequests == false {
                    self.processResponse = [
                        "notification": "Error (no API response). Auto-retrying." as AnyObject,
                        "image": "",
                        "imageTitle": ""
                    ]
                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                    self.processRetryRequestWithPage(methodArguments, pageNumber: pageNumber)
                }
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
                                
                                /**
                                 *  Loop through array of photos, choose only
                                 *  4 random photo indexes, and add them to a new array
                                 */
                                var randomPhotosIndexes: [Int] = []
                                var randomPhotoIndex: Int = 0
                                for i in 1...4 {
                                    randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                                    randomPhotosIndexes.append(randomPhotoIndex)
                                }

                                print("randomPhotoIndexes are: \(randomPhotosIndexes)")
                                
                                /**
                                 *  Loop through the initial photos array and fetch the
                                 *  contents at the 4 random photos indexes, and add their
                                 *  contents to a dictionary
                                 */
                                
                                let photoDictionary1 = photosArray[randomPhotosIndexes[0]] as [String: AnyObject]
                                let photoDictionary2 = photosArray[randomPhotosIndexes[1]] as [String: AnyObject]
                                let photoDictionary3 = photosArray[randomPhotosIndexes[2]] as [String: AnyObject]
                                let photoDictionary4 = photosArray[randomPhotosIndexes[3]] as [String: AnyObject]

                                /**
                                 *  Assign to variables for each photo in the 
                                 *  dictionary, its title and url.
                                 */

                                if let photoTitle1 = photoDictionary1["title"] as? String {
                                    self.photoTitle1 = photoTitle1
                                }
                                if let photoTitle2 = photoDictionary2["title"] as? String {
                                    self.photoTitle2 = photoTitle2
                                }
                                if let photoTitle3 = photoDictionary3["title"] as? String {
                                    self.photoTitle3 = photoTitle3
                                }
                                if let photoTitle4 = photoDictionary4["title"] as? String {
                                    self.photoTitle4 = photoTitle4
                                }

                                /**
                                 *   Get the photo dictionary URL property for each 
                                 *   of the 4 random photos if they exist
                                 */

                                if let imageUrlString1 = photoDictionary1["url_m"] as? String {
                                    let imageURL1 = NSURL(string: imageUrlString1)
                                    if let imageData1 = NSData(contentsOfURL: imageURL1!) {
                                        self.imageUrlString1 = imageUrlString1
                                    }
                                }

                                if let imageUrlString2 = photoDictionary2["url_m"] as? String {
                                    let imageURL2 = NSURL(string: imageUrlString2)
                                    if let imageData2 = NSData(contentsOfURL: imageURL2!) {
                                        self.imageUrlString2 = imageUrlString2
                                    }
                                }

                                if let imageUrlString3 = photoDictionary3["url_m"] as? String {
                                    let imageURL3 = NSURL(string: imageUrlString3)
                                    if let imageData3 = NSData(contentsOfURL: imageURL3!) {
                                        self.imageUrlString3 = imageUrlString3
                                    }
                                }

                                if let imageUrlString4 = photoDictionary4["url_m"] as? String {
                                    let imageURL4 = NSURL(string: imageUrlString4)
                                    if let imageData4 = NSData(contentsOfURL: imageURL4!) {
                                        self.imageUrlString4 = imageUrlString4
                                    }
                                }

                                /**
                                *   Check that at least 1 out of the 4 random photo url's
                                *   exist before advising that images were found
                                */
                                
                                if (self.imageUrlString1 != "" && self.imageUrlString2 != "" && self.imageUrlString3 != "" && self.imageUrlString4 != "") {

                                    /**
                                     *  Note: Attempted to send images and image titles
                                     *  as an array but got error
                                     *  "Could not cast value of type 
                                     *  'Swift._SwiftDeferredNSArray' to 'NSString'.
                                     *  I expect since since dictionary has strict typing
                                     */
                                    self.processResponse = [
                                        "notification": "Success. Found image(s)." as AnyObject,
                                        "image": self.imageUrlString1!,
                                        "image2": self.imageUrlString2!,
                                        "image3": self.imageUrlString3!,
                                        "image4": self.imageUrlString4!,
                                        "imageTitle": self.photoTitle1!,
                                        "imageTitle2": self.photoTitle2!,
                                        "imageTitle3": self.photoTitle3!,
                                        "imageTitle4": self.photoTitle4!
                                    ]
                                    
                                    /**
                                     *  Upon success, invalidate the timer, reset page history
                                     *  and cancel API requests
                                     */
                                    if self.flickrRequestWithPageTimer != nil {
                                        if self.flickrTask != nil {
                                            self.flickrTask!.cancel()
                                        }
                                        if self.flickrTaskWithPage != nil {
                                            self.flickrTaskWithPage!.cancel()
                                        }
                                        if self.flickrRequestTimer != nil {
                                            self.flickrRequestTimer!.invalidate()
                                        }
                                        if self.flickrRequestWithPageTimer != nil {
                                            self.flickrRequestWithPageTimer!.invalidate()
                                        }
                                        self.randomPageRetryHistory = []
                                    }
                                    if self.cancelFlickrRequests == false {
                                        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                                    }
                                } else {
                                    print("Error (no image response) at image URL. Auto-retrying.")
                                    if self.cancelFlickrRequests == false {
                                        self.processResponse = [
                                            "notification": "Error (no image response). Auto-retrying." as AnyObject,
                                            "image": "",
                                            "imageTitle": ""
                                        ]
                                        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                                        self.processRetryRequestWithPage(methodArguments, pageNumber: pageNumber)
                                    }
                                }
                            } else {
                                print("Error (no image response) only an empty array")
                                if self.cancelFlickrRequests == false {
                                    self.processResponse = [
                                        "notification": "Error (no image response). Auto-retrying." as AnyObject,
                                        "image": "",
                                        "imageTitle": ""
                                    ]
                                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                                    self.processRetryRequestWithPage(methodArguments, pageNumber: pageNumber)
                                }
                            }
                        } else {
                            print("Error (API). Missing key 'photo' in \(photosDictionary)")
                            if self.cancelFlickrRequests == false {
                                self.processResponse = [
                                    "notification": "Error (API)." as AnyObject,
                                    "image": "",
                                    "imageTitle": ""
                                ]
                                NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                            }
                        }
                    } else {
                        print("Error (API). No photos found using key 'total'. Auto-retrying.")
                        if self.cancelFlickrRequests == false {
                            self.processResponse = [
                                "notification": "Error (no image response). Auto-retrying." as AnyObject,
                                "image": "",
                                "imageTitle": ""
                            ]
                            NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                            self.processRetryRequestWithPage(methodArguments, pageNumber: pageNumber)
                        }
                    }
                } else {
                    print("Error (API). Missing key 'photos' in \(parsedResult)")
                    if self.cancelFlickrRequests == false {
                        self.processResponse = [
                            "notification": "Error (API)." as AnyObject,
                            "image": "",
                            "imageTitle": ""
                        ]
                        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                    }
                }
            }
        }
        
        self.flickrTaskWithPage!.resume()
    }
}