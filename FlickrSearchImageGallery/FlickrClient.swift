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
                    "notification": "Error (no API response). Try again" as AnyObject,
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
                            "notification": "Error (API). Contact developer." as AnyObject,
                            "image": "",
                            "imageTitle": ""
                        ]
                        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                    }
                } else {
                    print("Error (API). Missing key 'photos' in \(parsedResult)")
                    self.processResponse = [
                        "notification": "Error (API). Contact developer." as AnyObject,
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
                    "notification": "Error (API). Contact developer." as AnyObject,
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
                                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                                print("randomPhotoIndex is: \(randomPhotoIndex)")
                                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                                print("photoDictionary is: \(photoDictionary)")
                                
                                let photoTitle = photoDictionary["title"] as? String
                                let imageUrlString = photoDictionary["url_m"] as? String
                                let imageURL = NSURL(string: imageUrlString!)
                                
                                if let imageData = NSData(contentsOfURL: imageURL!) {
                                    self.processResponse = [
                                        "notification": "Success. Found image." as AnyObject,
                                        "image": imageUrlString!,
                                        "imageTitle": "\(photoTitle!)"
                                    ]
                                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                                } else {
                                    print("Error (no image in response) at \(imageURL)")
                                    self.processResponse = [
                                        "notification": "Error (no image in response). Try again." as AnyObject,
                                        "image": "",
                                        "imageTitle": ""
                                    ]
                                    NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                                }
                            } else {
                                print("Error (no image in response) only an empty array")
                                self.processResponse = [
                                    "notification": "Error (no image in response). Try again." as AnyObject,
                                    "image": "",
                                    "imageTitle": ""
                                ]
                                NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                            }
                        } else {
                            print("Error (API). Missing key 'photo' in \(photosDictionary)")
                            self.processResponse = [
                                "notification": "Error (API). Contact developer." as AnyObject,
                                "image": "",
                                "imageTitle": ""
                            ]
                            NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                        }
                    } else {
                        print("Error (API). No photos found using key 'total'")
                        self.processResponse = [
                            "notification": "Error (no photo in response). Try again." as AnyObject,
                            "image": "",
                            "imageTitle": ""
                        ]
                        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientProcessResponseNotification, object: self.processResponse)
                    }
                } else {
                    print("Error (API). Missing key 'photos' in \(parsedResult)")
                    self.processResponse = [
                        "notification": "Error (API). Contact developer." as AnyObject,
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