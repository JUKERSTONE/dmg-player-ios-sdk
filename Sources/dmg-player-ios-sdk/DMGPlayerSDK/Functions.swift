// Functions.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK {
//    func loadBkVideoInPrimaryWebView(url: URL) {
//        let request = URLRequest(url: url)
//        print("bk load")
//        bkWebView.load(request)
//    }
    
    func loadBkWebViewBuffer(urls: [URL]) {
//        let request = URLRequest(url: url)
//        print("bk load")
//        bkWebView.load(request)
    }
    
    func loadVideoInPrimaryWebView(url: URL) {
        let request = URLRequest(url: url)
        primaryWebView.load(request)
    }
    
    func loadVideoInSecondaryWebView(url: URL) {
        let request = URLRequest(url: url)
        secondaryWebView.load(request)
    }

    func preloadNextWebView() {
        guard index + 1 < queue.count else {
            print("Not enough elements in queue to preload")
            return
        }

        let nextIsrc = queue[index + 1]

        let apiService = APIService.shared
        let urlString = "https://europe-west1-trx-traklist.cloudfunctions.net/TRX_DEVELOPER/trx/music/\(nextIsrc)"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        apiService.fetchData(from: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let urlStringWithQuotes = String(data: data, encoding: .utf8) else {
                        print("The data received could not be converted to a string.")
                        return
                    }

                    print(urlStringWithQuotes)
                    let urlString = urlStringWithQuotes.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

                    guard let videoURL = URL(string: urlString) else {
                        print("The cleaned string is not a valid URL: \(urlString)")
                        return
                    }

                    print("preload bk")
//                    if self?.isBkActive == false {
//                        self?.loadBkVideoInPrimaryWebView(url: videoURL)
//                    }

                    if self?.isPrimaryActive == true {
                        self?.loadVideoInSecondaryWebView(url: videoURL)
                    } else {
                        self?.loadVideoInPrimaryWebView(url: videoURL)
                    }

                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        }
    }
    
    func play(webView: WKWebView) {
        // Check the application's state
        if UIApplication.shared.applicationState == .active {
            // App is in the foreground
            webView.evaluateJavaScript(buildActiveJavaScript(), completionHandler: { _, error in
                if let error = error {
                    print("Error during JavaScript execution: \(error.localizedDescription)")
                } else {
                    print("JavaScript executed successfully in foreground.")
                }
            })

            self.isBkActive = false
        } else {
            print("STEP 3: EXECUTE TRACK IN WEBVIEW")
            self.bkWebViews[index].evaluateJavaScript(buildActiveJavaScript(), completionHandler: { _, error in
                if let error = error {
                    print("Error during Java1Script execution: \(error.localizedDescription)")
                } else {
                    print("JavaScript executed successfully in foreground.")
                }
                self.isFreeloading = true
            })

            self.isBkActive = true
        }
    }

    
    func updatedPreload(buffer: [String], index: Int) {
        let apiService = APIService.shared
        let urlString = "https://europe-west1-trx-traklist.cloudfunctions.net/TRX_DEVELOPER/trx/music/buffer"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        // Convert your buffer array into JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: buffer, options: []) else {
            print("Failed to serialize buffer to JSON")
            return
        }

        // Print JSON string for debugging
        if let jsonString = apiService.json(from: buffer) {
            print("JSON String to be sent: \(jsonString)")
        }

        // Perform the POST request
        apiService.postData(to: url, body: jsonData) { result in
            switch result {
            case .success(let data):
                // Attempt to convert the data to a JSON array
                // You must use 'try?' here because you are inside a closure that does not allow throwing functions.
                if let urlStringArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                    // Now on the main queue, you can update your UI or perform other operations
                    DispatchQueue.main.async {
                        // Map the array of string URLs to actual URL objects
                        let urls = urlStringArray.compactMap { urlString -> URL? in
                            return URL(string: urlString.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
                        }
                        
                        if self.isBkActive == false {
                            self.loadBkWebViewBuffer(urls: urls)
                        }
                        
                        let videoURL = urls[index + 1]

                        if self.isPrimaryActive == true {
                            self.loadVideoInSecondaryWebView(url: videoURL) // next up
                        } else {
                            self.loadVideoInPrimaryWebView(url: videoURL) // next up
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        print("The received data is not an array of strings.")
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Failed to update preload:", error)
                }
            }
        }

    }
}

public func buildActiveJavaScript() -> String {
    return """
    if (!window.trakStarVideo) {
        window.trakStarVideo = document.getElementsByTagName('video')[0];
    }
    window.trakStarVideo.muted = false;
    window.trakStarVideo.play();
    window.trakStarVideo.requestPictureInPicture().then(() => {
        const message = {
            eventType: 'enablePiP',
            data: 'PiP initiated successfully.'
        };
        window.webkit.messageHandlers.player.postMessage(JSON.stringify(message));
    }).catch(error => {
        const message = {
            eventType: 'enablePiP',
            data: 'PiP initiation failed: ' + error.message
        };
        window.webkit.messageHandlers.player.postMessage(JSON.stringify(message));
    });
    """
}

public func buildInactiveJavaScript() -> String {
    return """
    if (!window.trakStarVideo) {
        window.trakStarVideo = document.getElementsByTagName('video')[0];
    }
    window.trakStarVideo.muted = true;
    window.trakStarVideo.pause();
    """
}

public func buildPauseJavaScript() -> String {
    return """
    if (!window.trakStarVideo) {
        window.trakStarVideo = document.getElementsByTagName('video')[0];
    }
    window.trakStarVideo.muted = true;
    window.trakStarVideo.pause();
    """
}

public func buildPlayJavaScript() -> String {
    return """
    if (!window.trakStarVideo) {
        window.trakStarVideo = document.getElementsByTagName('video')[0];
    }
    window.trakStarVideo.muted = false;
    window.trakStarVideo.play();
    """
}

public func buildCommonJavaScript() -> String {
    return """
        if (!window.trakStarVideo) {
            window.trakStarVideo = document.getElementsByTagName('video')[0];
        }
        
        window.trakStarVideo = document.getElementsByTagName('video')[0];
        
        window.trakStarVideo.addEventListener('loadedmetadata', () => {
            window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                eventType: 'videoReady',
                data: true
            }));
        });
        
        window.trakStarVideo.addEventListener('ended', function() {
            window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                eventType: 'videoEnded',
                data: 100
            }));
        });
        
        window.trakStarVideo.addEventListener('timeupdate', () => {
            window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                eventType: 'videoProgress',
                data: (window.trakStarVideo.currentTime / window.trakStarVideo.duration) * 100
            }));
        });
        
        window.trakStarVideo.addEventListener('error', function() {
            window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                eventType: 'videoError',
                data: 'An error occurred while trying to load the video.'
            }));
        });
        true;
    """
}
    
//    public func buildFreeloadJavaScript() -> String {
//        let jsCodeCommon = """
//            window.location.href = 'https://www.youtube.com/watch?v=PY0yMKzJw7g';
//        """
//
//        return jsCodeCommon
//    }


