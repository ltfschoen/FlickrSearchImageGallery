//
//  FlickrClientXML.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 25/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import Foundation

/// Notification generated when a product is purchased.
public let FlickrClientXMLProcessResponseNotification = "FlickrClientXMLProcessResponseNotification"

/**
 *  Flickr Client class to perform communication with Flickr API's XML Endpoint
 */
class FlickrClientXML: NSObject, NSXMLParserDelegate {

    // MARK: Properties
    
    var flickrImages: [FlickrImage]?
    
    // Unit Testing variables
    var testData = NSBundle.mainBundle().pathForResource("photos_public", ofType: "xml")
    var testDataOn: Bool = true
    
    // Parsing XML session variables
    var parser: NSXMLParser?
    var flickrTaskXML: NSURLSessionDataTask?
    var entries = NSMutableArray()
    var elements = NSMutableDictionary()
    var element = NSString()
    var id = NSMutableString()
    var title = NSMutableString()
    var imageUrlBig = NSString()
    var imageUrlThumb = NSString()
    var tags: Array<String> = []
    var searchTerm: AnyObject?
    var searchTermArr: Array<String> = []

    /**
     *  Request to Flickr API's XML Endpoint.
     */
    func getImageFromFlickrBySearchXMLEndpoint(methodArguments: [String : AnyObject]) {
        self.searchTerm = methodArguments["text"]! as AnyObject
        let session = NSURLSession.sharedSession()
        let urlString = ENDPOINT_URL_XML
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        self.flickrTaskXML = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Error (no API response): \(error)")
            } else if data == nil {
                print("Error (data is nil error)")
                return
            } else {
                /**
                 *  Parse the Sample XML File instead of the ENDPOINT_URL_XML
                 *  when testDataOn is triggered during Unit Testing
                 */
                if self.testDataOn == true {
                    self.parser = NSXMLParser(contentsOfURL: NSURL(fileURLWithPath: self.testData!))
                } else {
                    self.parser = NSXMLParser(data: data!)
                }
                self.parser!.delegate = self

                // Progress XML linearly calling delegate methods
                self.parser!.parse()
            }
        }
        self.flickrTaskXML!.resume()
    }

    // MARK: Parser Delegate Methods

    func parserDidStartDocument(parser: NSXMLParser) {
        self.entries.removeAllObjects()
    }

    // didStartElement occurs each time the parse finds an XML key
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
//        print("Element name: \(elementName)")
//        print("Element attributes: \(attributeDict)")

        self.element = elementName
        
        // Switch to obtain nested XML keys/attributes
        switch elementName {
        case "id":
            self.elements = NSMutableDictionary()
            self.elements = [:]
            self.id = NSMutableString()
            self.id = ""
        case "title":
            self.title = NSMutableString()
            self.title = ""
        case "link":
            if attributeDict["rel"] != "alternate" {
                self.imageUrlBig = attributeDict["href"]! as String
            }
        case "category":
            if attributeDict["term"] != "" {
                self.tags.append(attributeDict["term"]!)
            }
        default:
            break
        }

    }
    
    /* 
     *  foundCharacters occurs each time the parser enters a <key> and
     *  progressively appends characters contained within the key to a
     *  predefined variable.
     */
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        
        // Check current element being parsed
        if self.element.isEqualToString("id") {
            self.id.appendString(string)
        } else if self.element.isEqualToString("title") {
            self.title.appendString(string)
        }

    }

    /*
     *  didEndElement occurs each time the parser finds the end of the element
     *  defined by </tag>, when the whole set of characters for all its
     *  inner XML tags are collated it sets them as the value of a key in
     *  the elements dictionary for this element, and adds this as an element
     *  within the entries array.
     */
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        if (elementName as NSString).isEqualToString("entry") {
            if !self.id.isEqual(nil) {
                self.elements.setObject(self.id, forKey: "id")
                let trimmedId = self.id.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                self.elements.setObject(trimmedId, forKey: "id")
                if !self.title.isEqual(nil) {
                    let trimmedTitle = self.title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    self.elements.setObject(trimmedTitle, forKey: "title")
                    if !self.imageUrlBig.isEqual(nil) {
                        self.elements.setObject(self.imageUrlBig, forKey: "image_big")

                        if !self.imageUrlThumb.isEqual(nil) {
                            // Create Thumbnail URL cloning and modifying big url
                            self.imageUrlThumb = self.imageUrlBig.stringByReplacingOccurrencesOfString("b.jpg", withString: "t.jpg")
                            self.elements.setObject(self.imageUrlThumb, forKey: "img_thumb")
                        
                            if !self.tags.isEmpty {
                                self.elements.setObject(self.tags, forKey: "tags")
                            }
                        }
                    }
                }
            }

            print("Elements: \(self.elements)")
            self.entries.addObject(self.elements)
        }

    }

    // Runs after didEndElement has been run for all the XML document elements
    func parserDidEndDocument(parser: NSXMLParser) {
        print("Entries: \(self.entries)")
        
        let imagesParsed = self.entries

        // Remove images where metadata does not contain any tag(s) given by user
        let imagesParsedWithTags: NSMutableArray = self.filterByImagesMatchingGivenTags(imagesParsed, searchTermArr: self.searchTermArr)

        self.flickrImages = imagesParsedWithTags.map {
            imageDictionary in
            
            /** 
             *  Note that ?? is the nil coalescing operator. When
             *  imageDictionary key not nil it is unwrapped and value returned. 
             *  Otherwise if it is nil then "" returned (gives a default
             *  value when an optional is nil.
             */
            let id = imageDictionary["id"] as? String ?? ""
            let title = imageDictionary["title"] as? String ?? ""
            let imageUrlBig = imageDictionary["image_big"] as? String ?? ""
            let imageUrlThumb = imageDictionary["image_thumb"] as? String ?? ""
            let tags = imageDictionary["tags"] as? [String] ?? [""]
            let flickrImage = FlickrImage(id: id, title: title, imageUrlBig: imageUrlBig, imageUrlThumb: imageUrlThumb, tags: tags)
            
            return flickrImage
        }
        print("Flickr Images: \(self.flickrImages)")

        NSNotificationCenter.defaultCenter().postNotificationName(FlickrClientXMLProcessResponseNotification, object: imagesParsedWithTags)
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        print("Error: parseErrorOccurred: \(parseError)")
    }

    func filterByImagesMatchingGivenTags(imagesParsed: NSMutableArray, searchTermArr: Array<String>) -> NSMutableArray {
        
        // Immediately return with same parsed values if no search input field tags provided
        guard self.searchTerm?.length != 0 else { return imagesParsed }

        // Split Flickr tags (entered into the search input field) into an array
        self.searchTermArr = self.searchTerm!.componentsSeparatedByString(" ")
        
        // Deep Copy of parsing results for manipulation
        let copyOfImagesParsed: NSMutableArray = NSMutableArray(array: imagesParsed as [AnyObject], copyItems: true)
        
        // Avoid index out of bounds error
        var countRemovedFromImagesParsedWithTags = 0
        
        /**
         *  Iterate through each search term provided. For each search term
         *  iteration we iterate through the array of dictionaries where each
         *  dictionary contains metadata associated with a photo from the
         *  Flickr Public Photo API. We fetch the array value of the 'tags' key in
         *  each dictionary, modify a copy of it by keeping only alphanumeric characters
         *  and converting it to a string, and then search for a match.
         *  If there is a match, then we keep that dictionary, otherwise we remove it.
         *  Note: Iterate over the original parsed array of dictionaries, but
         *  only remove dictionaries with no matching tags from the copy of it
         *  (otherwise index out of range error since array count will reduce)
         */
        
        for term in 0 ..< self.searchTermArr.count {
            for element in 0 ..< imagesParsed.count {
                let currentTagArr: Array<String> = imagesParsed[element]["tags"] as! Array<String>
                let currentTagArrStringRep = currentTagArr.joinWithSeparator("")
                
                // Filter the tag element so it only contains alphanumeric characters
                let currentTagArrStringRepWithAlphanumericFilter: NSString = currentTagArrStringRep.componentsSeparatedByCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet).joinWithSeparator("")
                print("Alphanumeric form of tags: \(currentTagArrStringRepWithAlphanumericFilter)")
                
                /*
                 *  Check if alphanumeric representation of all the tags contains
                 *  the 'tag' term currently being iterated in the outer loop.
                 *  If not, then remove the dictionary element from the array.
                 */
                if !currentTagArrStringRepWithAlphanumericFilter.containsString(self.searchTermArr[term]) {
                    // Remove from the copy of the original parsed results
                    copyOfImagesParsed.removeObjectAtIndex(element-countRemovedFromImagesParsedWithTags)
                    countRemovedFromImagesParsedWithTags += 1
                    print("Removed dictionary \(element) from parsed results. No matching tag detected.")
                }
            }
        }

        return copyOfImagesParsed
    }

}