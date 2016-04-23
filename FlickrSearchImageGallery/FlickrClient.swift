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
    var processResponse: [String: AnyObject]?

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
    
    /**
    *  Request random page from Flickr API. Call separate method to
    *  get image from random page
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
                self.processResponse = [
                    "notification": "Error (no API response).\rTry again." as AnyObject,
                    "image": "",
                    "imageTitle": ""
                ]
                NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
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
                        self.processResponse = [
                            "notification": "Error (API).\rContact developer." as AnyObject,
                            "image": "",
                            "imageTitle": ""
                        ]
                        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                    }
                } else {
                    print("Error (API). Missing key 'photos' in \(parsedResult)")
                    self.processResponse = [
                        "notification": "Error (API).\rContact developer." as AnyObject,
                        "image": "",
                        "imageTitle": ""
                    ]
                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                }
            }
        }
        task.resume()
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
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Error (no API response): \(error)")
                self.processResponse = [
                    "notification": "Error (API).\rContact developer." as AnyObject,
                    "image": "",
                    "imageTitle": ""
                ]
                NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
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
                                        "notification": "Success.\rFound image(s)." as AnyObject,
                                        "image": self.imageUrlString1!,
                                        "image2": self.imageUrlString2!,
                                        "image3": self.imageUrlString3!,
                                        "image4": self.imageUrlString4!,
                                        "imageTitle": self.photoTitle1!,
                                        "imageTitle2": self.photoTitle2!,
                                        "imageTitle3": self.photoTitle3!,
                                        "imageTitle4": self.photoTitle4!
                                    ]
                                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                                } else {
                                    print("Error (no image in response) at an image URL")
                                    self.processResponse = [
                                        "notification": "Error (no image in response).\rTry again." as AnyObject,
                                        "image": "",
                                        "imageTitle": ""
                                    ]
                                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                                }
                            } else {
                                print("Error (no image in response) only an empty array")
                                self.processResponse = [
                                    "notification": "Error (no image in response).\rTry again." as AnyObject,
                                    "image": "",
                                    "imageTitle": ""
                                ]
                                NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                            }
                        } else {
                            print("Error (API). Missing key 'photo' in \(photosDictionary)")
                            self.processResponse = [
                                "notification": "Error (API).\rContact developer." as AnyObject,
                                "image": "",
                                "imageTitle": ""
                            ]
                            NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                        }
                    } else {
                        print("Error (API). No photos found using key 'total'")
                        self.processResponse = [
                            "notification": "Error (no photo in response).\rTry again." as AnyObject,
                            "image": "",
                            "imageTitle": ""
                        ]
                        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                    }
                } else {
                    print("Error (API). Missing key 'photos' in \(parsedResult)")
                    self.processResponse = [
                        "notification": "Error (API).\rContact developer." as AnyObject,
                        "image": "",
                        "imageTitle": ""
                    ]
                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                }
            }
        }
        
        task.resume()
    }
}