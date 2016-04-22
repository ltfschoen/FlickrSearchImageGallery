//
//  ApiKeys.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 22/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import Foundation

func valueForAPIKey(named keyname:String) -> String {
    let filePath = NSBundle.mainBundle().pathForResource("ApiKeys", ofType: "plist")
    let plist = NSDictionary(contentsOfFile:filePath!)
    let value = plist?.objectForKey(keyname) as! String
    return value
}