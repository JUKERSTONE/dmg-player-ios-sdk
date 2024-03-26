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
    
    func loadVideoInPrimaryWebView(url: URL) {
        let request = URLRequest(url: url)
        foregroundPrimaryBuffer.load(request)
    }
    
    func loadVideoInSecondaryWebView(url: URL) {
        let request = URLRequest(url: url)
        foregroundSecondaryBuffer.load(request)
    }
    
    func play(webView: WKWebView) {
        if UIApplication.shared.applicationState == .active {
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
                if self.index + 1 < self.buffer.count {
                    let url = self.buffer[self.index + 1]
                    let javaScriptString = "window.location.href = '\(url)';"

                    freeloadingBuffer.evaluateJavaScript(javaScriptString) { result, error in
                       if let error = error {
                           print("Error injecting the 'load' event listener: \(error.localizedDescription)")
                       } else {
                           print("JavaScript executed successfully in foregroundr.")
                       }
                    }

                } else {
                    print("Index is out of range of the buffer array")
                }
            } else {
                backgroundPrimaryBuffer.evaluateJavaScript(buildActiveJavaScript(), completionHandler: { _, error in
                    if let error = error {
                        print("Error during Java1Script execution: \(error.localizedDescription)")
                    } else {
                        print("JavaScript executed successfully in foreground.")
                    }
                })
                
                self.isFreeloading = true
            }
            
            if self.index < self.queue.count - 1 {
                self.index += 1
            } else {
                print("Index is at the end of the queue")
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

            guard let jsonData = try? JSONSerialization.data(withJSONObject: buffer, options: []) else {
                print("Failed to serialize buffer to JSON")
                return
            }

            if let jsonString = apiService.json(from: buffer) {
                print("JSON String to be sent: \(jsonString)")
            }

            apiService.postData(to: url, body: jsonData) { result in
                switch result {
                case .success(let data):
                    if let urlStringArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                        DispatchQueue.main.async {
                            let urls = urlStringArray.compactMap { urlString -> URL? in
                                return URL(string: urlString.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
                            }
                            
                            let nextUp = urls[1]
                            self.buffer = urls
                            
                            if 2 < urls.count {
                                
                                if self.isBkActive == false {
                                    self.loadBkVideoInPrimaryWebView(url: nextUp)
                                }
                                
                                if self.isPrimaryActive {
                                    self.loadVideoInSecondaryWebView(url: nextUp)
                                } else {
                                    self.loadVideoInPrimaryWebView(url: nextUp)
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

//    func preloadNextWebView() {
//        guard index + 1 < queue.count else {
//            print("Not enough elements in queue to preload")
//            return
//        }
//
//        let nextIsrc = queue[index + 1]
//
//        let apiService = APIService.shared
//        let urlString = "https://europe-west1-trx-traklist.cloudfunctions.net/TRX_DEVELOPER/trx/music/\(nextIsrc)"
//
//        guard let url = URL(string: urlString) else {
//            print("Invalid URL")
//            return
//        }
//
//        apiService.fetchData(from: url) { [weak self] result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let data):
//                    guard let urlStringWithQuotes = String(data: data, encoding: .utf8) else {
//                        print("The data received could not be converted to a string.")
//                        return
//                    }
//
//                    print(urlStringWithQuotes)
//                    let urlString = urlStringWithQuotes.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
//
//                    guard let videoURL = URL(string: urlString) else {
//                        print("The cleaned string is not a valid URL: \(urlString)")
//                        return
//                    }
//
//                    print("preload bk")
//                    if self?.isBkActive == true {
//                        if self?.isBkPrimaryActive == true {
//                            self?.loadBkVideoInSecondaryWebView(url: videoURL)
//                        } else {
//                            self?.loadBkVideoInPrimaryWebView(url: videoURL)
//                        }
//
//                        if let isActive = self?.isBkPrimaryActive {
//                            self?.isBkPrimaryActive = !isActive
//                        } else {
//                            // Handle the case where `isBkPrimaryActive` is nil
//                        }
//                    }
//
//                case .failure(let error):
//                    print("Error fetching data: \(error)")
//                }
//            }
//        }
//    }
