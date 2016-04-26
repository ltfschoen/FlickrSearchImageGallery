//
//  FlickrClientXML.swift
//  FlickrSearchImageGallery
//
//  Created by LS on 25/04/2016.
//  Copyright © 2016 Luke Schoen. All rights reserved.
//

import Foundation

/**
 *  Flickr Client class to perform communication with Flickr API's XML Endpoint
 */
class FlickrClientXML: NSObject, NSXMLParserDelegate {

    // MARK: Properties
    
    // Parsing XML session variables
    var flickrTaskXML: NSURLSessionDataTask?
    var entries = NSMutableArray()
    var elements = NSMutableDictionary()
    var element = NSString()
    var id = NSMutableString()
    var title = NSMutableString()
    var link = String()
    var imageUrlBig = NSString()
    var tags: Array<String> = []

    /**
     *  Request to Flickr API's XML Endpoint.
     */
    func getImageFromFlickrBySearchXMLEndpoint(methodArguments: [String : AnyObject]) {
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
                let parser = NSXMLParser(data: data!)
                parser.delegate = self

                // Progress XML linearly calling delegate methods
                parser.parse()
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
        
        print("Element name: \(elementName)")
        print("Element attributes: \(attributeDict)")

        element = elementName
        
        // Switch to obtain nested XML keys/attributes
        switch elementName {
        case "id":
            elements = NSMutableDictionary()
            elements = [:]
            id = NSMutableString()
            id = ""
            title = NSMutableString()
            title = ""
        case "link":
            if attributeDict["rel"] != "alternate" {
                imageUrlBig = attributeDict["href"]! as String
            }
        case "category":
            if attributeDict["term"] != "" {
                tags.append(attributeDict["term"]!)
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
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        
        if element.isEqualToString("id") {
            id.appendString(string!)
        } else if element.isEqualToString("title") {
            title.appendString(string!)
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
            if id.isEqual(nil) {
                let trimmedId = id.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                elements.setObject(trimmedId, forKey: "id")
                if !title.isEqual(nil) {
                    let trimmedTitle = id.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    elements.setObject(trimmedTitle, forKey: "title")
                    if !link.isEqual(nil) {
                        elements.setObject(imageUrlBig, forKey: "link")
                        if !tags.isEmpty {
                            elements.setObject(tags, forKey: "tags")
                        }
                    }
                }
            }
            entries.addObject(elements)
        }

    }

    // Runs after didEndElement has been run for all the XML document elements
    func parserDidEndDocument(parser: NSXMLParser) {
        print("Entries: \(entries)")

    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        print("Error: parseErrorOccurred: \(parseError)")
    }
}