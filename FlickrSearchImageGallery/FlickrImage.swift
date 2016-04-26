//
//  FlickrImage.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 26/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import UIKit

/*
 * <entry>
 *   <title>DSC_0646.JPG</title>
 *   <id>tag:flickr.com,2005:/photo/26038586064</id>
 *   <link rel="enclosure" type="image/jpeg" href="https://farm2.staticflickr.com/1705/26038553734_1b50e2e3a2_b.jpg" />
 *
 */
class FlickrImage: NSObject {
    let id: String
    let title: String
    let imageUrl: String
//    let imageThumbUrl: String

    init (id: String, title: String, imageUrl: String, imageThumbUrl: String) {
        self.id = id
        self.title = title
        self.imageUrl = imageUrl
//        self.imageThumbUrl = imageThumbUrl
    }

    //
}

