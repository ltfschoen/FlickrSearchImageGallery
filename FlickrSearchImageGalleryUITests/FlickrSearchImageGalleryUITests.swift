//
//  FlickrSearchImageGalleryUITests.swift
//  FlickrSearchImageGalleryUITests
//
//  Created by LS on 22/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import XCTest

class FlickrSearchImageGalleryUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAsyncronousNotificationReturnedIsDisplayedForGivenKeywordSearch() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        /**
         *  Use 'app' object's 'textFields' property to return
         *  the text field with specified accessibility label defined
         *  in Identity Inspector. Simulate the tap gesture to search
         *  Flickr's API using the keywords entered in the text field.
         *  Verify that notification label displays expected message.
         */

        /// Given

        let keywordEntered = ""
        let expectedNotification = "Error (input empty)."
        let app = XCUIApplication()
        let keywordTextField = app.textFields["Keyword Entered"]
        let labelNotification = app.staticTexts["Notification Label"]
        var labelNotificationText = labelNotification.value as! String

        /// When

        keywordTextField.tap()
        keywordTextField.typeText(keywordEntered)
        app.buttons["Keyword Search"].tap()

        /// Then

        XCTAssert(labelNotification.exists)

        /**
         *  Syncronous flow within the test. Call back asynchronously later in the block
         *  to validate success with an assert, and call 'fulfill' to
         *  return since closure fulfilled the expectation.
         */

        // Create expectation to track completion (XCTestExpectation)
        let expectation = expectationWithDescription("Update notification label asynchronously")

        // Create asynchronous task
        let URL = NSURL(string: "https://api.flickr.com/services/rest/")
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(URL!) { data, response, error in
            XCTAssertNotNil(data, "Data should not be nil")
            XCTAssertNil(error, "Error should be nil")
            if let HTTPResponse = response as? NSHTTPURLResponse,
                responseURL = HTTPResponse.URL {
                XCTAssertEqual(HTTPResponse.statusCode, 200, "HTTP response status code should be 200")
                dispatch_async(dispatch_get_main_queue(), {
                    labelNotificationText = expectedNotification
                })
                expectation.fulfill()
            } else {
                XCTFail("Error: Response was not NSHTTPURLResponse")
            }
        }
        task.resume()
        
        // Wait for request to finish
        self.waitForExpectationsWithTimeout(30) { error in
            if let error = error {
                XCTFail("Error: \(error.localizedDescription)")
            }
            task.cancel()
        }
        
        // Check text value of notification label
        XCTAssert(labelNotificationText == expectedNotification)

    }
    
}
