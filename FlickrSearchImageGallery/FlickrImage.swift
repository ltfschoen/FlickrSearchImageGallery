//
//  FlickrImage.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 26/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import UIKit

class FlickrImage: NSObject {
    let id: String
    let title: String
    let imageUrlBig: String
    let imageUrlThumb: String
    let tags: Array<String>

    init (id: String, title: String, imageUrlBig: String, imageUrlThumb: String, tags: Array<String>) {
        self.id = id
        self.title = title
        self.imageUrlBig = imageUrlBig
        self.imageUrlThumb = imageUrlThumb
        self.tags = tags
    }
}

