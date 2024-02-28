// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK {
    func loadVideoInPrimaryWebView(url: URL) {
            // Set active JS for primary web view
            let primaryScript = WKUserScript(
                source: buildActiveJavaScript(),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            
            // Set inactive JS for secondary web view
            let secondaryScript = WKUserScript(
                source: buildInactiveJavaScript(),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )

            // Clear any existing scripts to avoid duplicates
            primaryWebView.configuration.userContentController.removeAllUserScripts()
            secondaryWebView.configuration.userContentController.removeAllUserScripts()

            // Inject the scripts into the web views' content controllers
            primaryWebView.configuration.userContentController.addUserScript(primaryScript)
            secondaryWebView.configuration.userContentController.addUserScript(secondaryScript)

            // Load the URL request in primary web view
            let request = URLRequest(url: url)
            primaryWebView.load(request)
        }
        
        // Function to load video in secondary web view and set it as active
        func loadVideoInSecondaryWebView(url: URL) {
            // Set inactive JS for primary web view
            let primaryScript = WKUserScript(
                source: buildInactiveJavaScript(),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            
            // Set active JS for secondary web view
            let secondaryScript = WKUserScript(
                source: buildActiveJavaScript(),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )

            // Clear any existing scripts to avoid duplicates
            primaryWebView.configuration.userContentController.removeAllUserScripts()
            secondaryWebView.configuration.userContentController.removeAllUserScripts()

            // Inject the scripts into the web views' content controllers
            primaryWebView.configuration.userContentController.addUserScript(primaryScript)
            secondaryWebView.configuration.userContentController.addUserScript(secondaryScript)

            // Load the URL request in secondary web view
            let request = URLRequest(url: url)
            secondaryWebView.load(request)
        }

    func preloadNextWebView() {
        guard index + 1 < queue.count else {
            print("Not enough elements in queue to preload")
            return
        }

        let nextIsrc = queue[index + 1] // Access the second element

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
    
    func updatedPreload(isrc: String) {
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



