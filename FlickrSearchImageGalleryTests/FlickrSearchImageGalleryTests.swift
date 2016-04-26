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

    func testEscapedParametersGeneratedForJSONEndpointGivenConstants() {
        let flickrClient = FlickrClient()
        
        flickrClient.randomPageRetryHistory = [2,4,6,8,9]
        let apiParamsCorrect = ["method": "flickr.photos.search&", "nojsoncallback": 1, "extras": "url_m", "format": "json", "text": "tiger", "api_key": "123456789aa1234aaa1234a123a123a1"]
        let expectEscParamsCorrect = "?method=flickr.photos.search&&text=tiger&extras=url_m&nojsoncallback=1&format=json&api_key=123456789aa1234aaa1234a123a123a1"
        let checkEscParamsCorrect = flickrClient.escapedParameters(apiParamsCorrect)
        XCTAssertEqual(expectEscParamsCorrect, checkEscParamsCorrect, "Check that escaped parameters correctly returned given API parameters")
    }

    // FIXME: Implement asyncronous testing of the XML parsing using NSOperation similar to this example: http://stackoverflow.com/questions/30179777/how-do-i-fix-a-testing-issue-in-swift-when-i-forget-to-set-a-delegate
    func testDictionaryGeneratedForXMLEndpointUsingHistoryFlickrData() {

        let flickrAPI = FlickrAPI()
        let flickrClientXML = FlickrClientXML()
        flickrClientXML.testDataOn = true
        
        // 1. Define expectation
        let expectation = expectationWithDescription("Flickr Public API request completion parses given XML data and runs callback success closure")
        
        // 2. Exercise asynchronous code
//        let methodArguments = [:]
//        flickrAPI.getImageFromFlickrBySearchXMLEndpoint(methodArguments as! [String : AnyObject]) { success in
//
//            XCTAssertTrue(success)
        
            // Fulfill expectation in async callback
            expectation.fulfill()
//        }

        // 3. Wait for expectation to be fulfilled
        waitForExpectationsWithTimeout(1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            } else {
                
//                var expectedParsedData: String = NSBundle.mainBundle().pathForResource("expected_photos_public_parsed", ofType: "")!
//                let expectedParsedDataStringRepresentation = flickrClientXML.entries.componentsJoinedByString("")
//                XCTAssertEqual(expectedParsedDataStringRepresentation, expectedParsedData, "Check that Sample History XML Data from Flickr Public Photos API Endpoint equals the result parsed by FlickrClientXML class methods")

            }
        }
        
    }

    // FIXME
    func testFilterByImagesMatchingGivenTags() {
        let flickrClientXML = FlickrClientXML()
        
        let searchTermArr: Array<String> = ["abc"]
        
        let imagesParsed: NSMutableArray = [
            ["id": 1,
                "tags": ["asd3233'214lll", "h", "saf"]],
            ["id": 2,
                "tags": ["asd3233'214lll", "jjddd", "a"]],
            ["id": 3,
                "tags": ["asd3233'214lll", "jjddd", "aabc"]],
            ["id": 4,
                "tags": ["asd3233'214lll", "h", "saf"]]
        ]
//        XCTAssertEqual(flickrClientXML.filterByImagesMatchingGivenTags(imagesParsed, searchTermArr: searchTermArr), [["id": 3,"tags": ["asd3233'214lll", "jjddd", "aabc"]]], "Filter parsed XML into an empty array if no photos contain given tag in metadata")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
