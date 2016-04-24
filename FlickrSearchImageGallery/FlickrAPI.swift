//
//  FlickrAPI.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 22/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import Foundation

/**
 *  Singleton class to access Flickr and locally manage all Flickr data.
 *  This class uses the Facade Design Pattern to expose a simple FlickrAPI that accesses
 *  backend complex services including Flickr Client to handle remote communication. 
 *  FlickrAPI decouples these services from other classes interfacing that are hidden 
 *  behind the facade of FlickrAPI.
 */
class FlickrAPI: NSObject {
    
    // MARK: Private Properties

    private let flickrClient: FlickrClient

    // MARK: Initialisation
    
    override init() {
        flickrClient = FlickrClient()
        super.init()
    }
    
    // MARK: - API Search Methods

    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject]) {
        flickrClient.getImageFromFlickrBySearch(methodArguments)
    }

    func enableFlickrRequests() {
        flickrClient.cancelFlickrRequests = false
    }

    func cancelKeywordSearch() {
        if flickrClient.flickrTask != nil {
            flickrClient.flickrTask!.cancel()
        }
        if flickrClient.flickrTaskWithPage != nil {
            flickrClient.flickrTaskWithPage!.cancel()
        }
        if flickrClient.flickrRequestTimer != nil {
            flickrClient.flickrRequestTimer!.invalidate()
        }
        if flickrClient.flickrRequestWithPageTimer != nil {
            flickrClient.flickrRequestWithPageTimer!.invalidate()
        }
        flickrClient.randomPageRetryHistory = []
        flickrClient.cancelFlickrRequests = true
    }
    
    // MARK: - Thread Safe Singleton Pattern
    
    /**
    *  Threadsafe Singleton declaration of static constant to
    *  hold the single instance of class.
    *  Supports lazy initialisation since
    *  Swift lazily initialises class constants and variables
    *  and is thread safe by the definition of let
    */
    static let sharedInstance = FlickrAPI()
}
