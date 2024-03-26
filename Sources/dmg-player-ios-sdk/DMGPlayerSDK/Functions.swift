// Functions.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK {
    func loadBkVideoInPrimaryWebView(url: URL) {
        let request = URLRequest(url: url)
        print("bk load")
        backgroundPrimaryBuffer.load(request)
    }
    
    func loadBkVideoInSecondaryWebView(url: URL) {
        let javaScriptString = "window.location.href = '\(url)';"
        print(javaScriptString, "js")

        backgroundSecondaryBuffer.evaluateJavaScript(javaScriptString) { result, error in
           if let error = error {
               print("Error injecting the 'load' event listener: \(error.localizedDescription)")
           } else {
               print("JavaScript executed successfully in foregroundr.")
           }
        }
    }
    
    func loadVideoInPrimaryWebView(url: URL) {
        let request = URLRequest(url: url)
        foregroundPrimaryBuffer.load(request)
    }
    
    func loadVideoInSecondaryWebView(url: URL) {
        let request = URLRequest(url: url)
        foregroundSecondaryBuffer.load(request)
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
                    if self?.isBkActive == true {
                        if self?.isBkPrimaryActive == true {
                            self?.loadBkVideoInSecondaryWebView(url: videoURL)
                        } else {
                            self?.loadBkVideoInPrimaryWebView(url: videoURL)
                        }
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
            
            if self.index < self.queue.count - 1 {
                self.index += 1
            } else {
                print("Index is at the end of the queue")
            }

               self.isBkActive = false
        } else {
            if self.isFreeloading == true {
            print("freeloading yes")
     
                if self.index + 1 < self.buffer.count {
                    let url = self.buffer[self.index + 1]
                    let javaScriptString = "window.location.href = '\(url)';"
                    print(javaScriptString, "js")

                    freeloadingBuffer.evaluateJavaScript(javaScriptString) { result, error in
                       if let error = error {
                           print("Error injecting the 'load' event listener: \(error.localizedDescription)")
                       } else {
                           print("JavaScript executed successfully in foregroundr.")
                       }
                    }

                } else {
                    print("Index is out of range of the buffer array")
                    // Handle the case when the index is out of range
                }
                
            
            } else {
                
                if self.isBkPrimaryActive {
                    print("STEP 3: EXECUTE TRACK IN WEBVIEW")
                    backgroundPrimaryBuffer.evaluateJavaScript(buildActiveJavaScript(), completionHandler: { _, error in
                        if let error = error {
                            print("Error during Java1Script execution: \(error.localizedDescription)")
                        } else {
                            print("JavaScript executed successfully in foreground.")
                        }
                       
                    })
                } else {
                    backgroundSecondaryBuffer.evaluateJavaScript(buildActiveJavaScript(), completionHandler: { _, error in
                        if let error = error {
                            print("Error during Java1Script execution: \(error.localizedDescription)")
                        } else {
                            print("JavaScript executed successfully in foreground.")
                        }
                    })
                }
            }
            
            if self.index < self.queue.count - 1 {
                self.index += 1
            } else {
                print("Index is at the end of the queue")
            }
            
            if UIApplication.shared.applicationState != .active && !self.isFreeloading {
                self.isBkPrimaryActive = !self.isBkPrimaryActive
            }
            
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
                            
                            let nextUp = urls[1]
                            self.buffer = urls
                            
                            if 2 < urls.count {
                                
                                if self.isBkActive == false {
                                    self.loadBkVideoInPrimaryWebView(url: nextUp) // Assuming this method exists and loads the buffer.
                                }
                                
                                if self.isPrimaryActive {
                                    self.loadVideoInSecondaryWebView(url: nextUp) // Load "next up" URL in secondary web view
                                } else {
                                    self.loadVideoInPrimaryWebView(url: nextUp) // Load "next up" URL in primary web view
                                }
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
    window.trakStarVideo.muted = true;
    window.trakStarVideo.pause();
    """
}

public func buildPauseJavaScript() -> String {
    return """
    window.trakStarVideo.muted = true;
    window.trakStarVideo.pause();
    """
}

public func buildPlayJavaScript() -> String {
    return """
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


