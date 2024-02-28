// WKNavigation.swift

import SwiftUI
import WebKit

// Make sure to conform to WKNavigationDelegate if needed.
@available(iOS 13.0, *)
extension DMGPlayerSDK {
    func loadVideoInPrimaryWebView(url: URL) {
            let request = URLRequest(url: url)
            primaryWebView.load(request)
    }
    
    func loadVideoInSecondaryWebView(url: URL) {
            let request = URLRequest(url: url)
            secondaryWebView.load(request)
    }

    func preloadNextWebView() {
        guard let nextIsrc = queue.first else {
            print("Queue is empty")
            return
        }

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
                    // Remove quotation marks from the string
                    let urlString = urlStringWithQuotes.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                 
                    // Validate if the cleaned string is a valid URL
                    guard let videoURL = URL(string: urlString) else {
                        print("The cleaned string is not a valid URL: \(urlString)")
                        return
                    }
                    
                    // Load the URL in the inactive WebView
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

    
    private func muteAndPause(webView: WKWebView) {
        let script = "window.trakStarVideo.muted = true; window.trakStarVideo.pause();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func play(webView: WKWebView) {
        let script = """
            if (window.trakStarVideo) {
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
            } else {
                const message = {
                    eventType: 'enablePiP',
                    data: 'No video element found.'
                };
                window.webkit.messageHandlers.player.postMessage(JSON.stringify(message));
            };
            """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func preloadNextVideo(isrc: String) {
        let apiService = APIService.shared
        let urlString = "https://europe-west1-trx-traklist.cloudfunctions.net/TRX_DEVELOPER/trx/music/\(isrc)"

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

                    // Remove quotation marks from the string
                    let urlString = urlStringWithQuotes.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

                    // Validate if the cleaned string is a valid URL
                    guard let videoURL = URL(string: urlString) else {
                        print("The cleaned string is not a valid URL: \(urlString)")
                        return
                    }

                    // Load the URL in the WebView
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
}



