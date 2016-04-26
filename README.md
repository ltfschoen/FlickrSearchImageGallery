Flickr Search Image Gallery App
========

Specification
========
[Client Specification](./SPEC.md)

Development Simulation & Testing Steps
========

* Development Simulation

  1. Start Xcode 7.3

  2. Simulate with Project > Run

  ** XML Flickr Public Photos API Endpoint **

  3a. Enter Tag(s) into the input field (NOT NECESSARY to search) (i.e. "square") to search Flickr XML public photos endpoint using Tag(s). Alternatively, do not enter any tags. Press "Search XML" button. 

    - Note 1: When searching XML, only the Tag Input Field and XML button will remain visible.
    - Note 2: Search parses and returns all the Flickr XML API Public photos (likely more than one)accompanied by their Title metadata. Only four (4) randomly chosen images are retrieved for each search. Warning: If a Tag has been entered into the Tag Input Field then only photos that have Tag metadata that matches the entered tag(s) will be returned (if any). Auto-retry and server failure notifications are only enabled for the JSON Flickr API search. 

  4a. Cancel button is functionality is limited to cancelling the XML Flickr API server request.

  5a. Wait for four (4) image thumbnail results and associated image metadata (title) to display. 
    - Note 1: If the UI becomes unresponsive, please wait whilst the images finish loading.
    - Note 2: Even if the Activity Spinner stops spinning, please wait for the photos to load.

  6a. Single Tap thumbnail image to navigate into its larger version (Single Tap anywhere to close larger version view). 

  7a. Double Tap thumbnail image to Share or Save the image (i.e. email, social media, save to system gallery)

  ** JSON Flickr API Endpoint **

  3b. Enter Tags(s) into the input field (NECESSARY to search) (i.e. "dog") to search Flickr JSON photos endpoint. Press "Search JSON" button. 

    - Note 1: When searching JSON, only the Tag Input Field and Cancel button remain visible.
    - Note 2: Search parses random page from all the Flickr JSON API (using API KEY) photo pages for photos with metadata matching entered tag(s). When the Flickr API server does not response (or no internet connection), or no matching images are found on that random page, then the requests will automatically retry and the user will be advised of this status through a notification. For each successive response failure, an algorithm inspects the history of previously parsed pages for this request, and selects another random page that is unique (not a random page that was previously parsed). Only four (4) image thumbnails are retrieved along with their accompanying metadata title.

  4b. (Optional) Cancel the current Flickr API request prior to making another request by pressing the Cancel Button. This may be necessary if automatic-retries continually fail, try using different tag(s) and press the Search Button again.

    - Note: The Search Button disappears during a Flickr API request to prevent multiple search requests being displayed and removed rapidly, causing user confusion.

  5b. Wait for four (4) image thumbnail results and associated image metadata (title) to display. 
    - Note: If the UI becomes unresponsive, please wait whilst the images finish loading.

  6b. Single Tap thumbnail image to navigate into its larger version (Single Tap anywhere to close larger version view). 

  7b. Double Tap thumbnail image to Share or Save the image (i.e. email, social media, save to system gallery)

* Testing and Coverage

  1. Enable Test Coverage in Xcode 7 (Edit Scheme > Test > Coverage > Gather code coverage > ON)

  2. Run XCTests for Unit Tests and UI Tests by pressing CMD + U

  3. View Coverage results in Report Navigator (Click latest Test > Click Coverage)

  Note: Alternative is to run XCTest from Command Line

```
xcodebuild test -project FlickrSearchImageGallery.xcodeproj -scheme FlickrSearchImageGallery -destination 'platform=iOS Simulator,name=iPhone 5s,OS=9.3'
```