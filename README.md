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

  3. Enter Keyword(s) into the input field. Press "Search" button. 

    - Note: Search parses random page from all the Flickr API photo pages for photos with metadata matching entered keyword(s). When the Flickr API server does not response (or no internet connection), or no matching images are found on that random page, then the requests will automatically retry and the user will be advised of this status through a notification. For each successive response failure, an algorithm inspects the history of previously parsed pages for this request, and selects another random page that is unique (not a random page that was previously parsed). Only four (4) image thumbnails are retrieved along with their accompanying metadata title.

  4. (Optional) Cancel the current Flickr API request prior to making another request by pressing the Cancel Button. This may be necessary if automatic-retries continually fail, try using different keyword(s) and press the Search Button again.

    - Note: The Search Button disappears during a Flickr API request to prevent multiple search requests being displayed and removed rapidly, causing user confusion.

  5. Wait for four (4) image thumbnail results and metadata title to display. 

    - Note: If the UI becomes unresponsive, please wait whilst the images finish loading.

* Testing

  1. Run XCTest from Command Line

```
xcodebuild test -project FlickrSearchImageGallery.xcodeproj -scheme FlickrSearchImageGallery -destination 'platform=iOS Simulator,name=iPhone 5s,OS=9.3'
```
