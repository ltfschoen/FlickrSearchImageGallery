//
//  FlickrSearchImageGalleryTests.swift
//  FlickrSearchImageGalleryTests
//
//  Created by LS on 22/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import XCTest
@testable import FlickrSearchImageGallery

class FlickrSearchImageGalleryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRandomPageGeneratedForRetryRequestIsUnique() {
        let flickrClient = FlickrClient()
        flickrClient.randomPageRetryHistory = [2,4,6,8,9]
        let expectDup = true
        let checkDup = flickrClient.checkForDuplicateInRandomPageHistory(8)
        XCTAssertEqual(expectDup, checkDup, "Check for duplicate in random page history should return true for given duplicate random page")
        let expectNotDup = false
        let checkNotDup = flickrClient.checkForDuplicateInRandomPageHistory(5)
        XCTAssertEqual(expectNotDup, checkNotDup, "Check for duplicate in random page history should return false for given non-duplicate random page")
    }

    func testEscapedParametersGeneratedForApiUrlGivenConstants() {
        let flickrClient = FlickrClient()
        
        flickrClient.randomPageRetryHistory = [2,4,6,8,9]
        let apiParamsCorrect = ["method": "flickr.photos.search&", "nojsoncallback": 1, "extras": "url_m", "format": "json", "text": "tiger", "api_key": "123456789aa1234aaa1234a123a123a1"]
        let expectEscParamsCorrect = "?method=flickr.photos.search&&text=tiger&extras=url_m&nojsoncallback=1&format=json&api_key=123456789aa1234aaa1234a123a123a1"
        let checkEscParamsCorrect = flickrClient.escapedParameters(apiParamsCorrect)
        XCTAssertEqual(expectEscParamsCorrect, checkEscParamsCorrect, "Check that escaped parameters correctly returned given API parameters")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
