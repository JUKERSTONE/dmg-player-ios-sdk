// Module.swift

import SwiftUI
import WebKit


@available(iOS 13.0, *)
public class DMGPlayerSDK: NSObject, ObservableObject, WKScriptMessageHandler {
    public var primaryWebView: WKWebView
    public var secondaryWebView: WKWebView
    public var index: Int
    public var isPaused: Bool
    @Published var hasPreloadedNextWebview: Bool = true
    @Published var isPrimaryActive: Bool = true
    @Published var queue: [String] = []
    
    public override init() {
        self.queue = []
        self.primaryWebView = WKWebView()
        self.secondaryWebView = WKWebView()
        self.isPrimaryActive = true
        self.index = 0
        self.isPaused = false

        super.init()

        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "player")
        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        
        self.primaryWebView = WKWebView(frame: .zero, configuration: config)
        self.secondaryWebView = WKWebView(frame: .zero, configuration: config)
        self.primaryWebView.navigationDelegate = self
        self.secondaryWebView.navigationDelegate = self
    }

    
    public func playNow(isrc: String) {
            queue.insert(isrc, at: 0)
        
            let apiService = APIService.shared  // Assuming APIService is your custom class for making network requests
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
                        
                        let urlString = urlStringWithQuotes.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                     
                        guard let videoURL = URL(string: urlString) else {
                            print("The cleaned string is not a valid URL: \(urlString)")
                            return
                        }
                    
                        DispatchQueue.main.async { [weak self] in
                            if self?.isPrimaryActive == true {
                                self?.loadVideoInPrimaryWebView(url: videoURL)
                            } else {
                            	self?.loadVideoInSecondaryWebView(url: videoURL)
                            }

                        }
                    case .failure(let error):
                        print("Error fetching data: \(error)")
                    }
                }
            }
    }

    public func queueNext(isrc: String) {
        queue.insert(isrc, at: 1)
    }

    public func queue(isrc: String) {
        queue.append(isrc)
    }
    
    public func printQueue() {
        print(queue)
    }
    
    public func removeFromQueue(isrc: String) {
        queue = queue.filter { $0 != isrc }
    }

    
    public func pause() {
        if isPrimaryActive {
            primaryWebView.evaluateJavaScript(buildPauseJavaScript(), completionHandler: nil)
        } else {
            secondaryWebView.evaluateJavaScript(buildPauseJavaScript(), completionHandler: nil)
        }
    }
    
    public func resume() {
        if isPrimaryActive {
            primaryWebView.evaluateJavaScript(buildPlayJavaScript(), completionHandler: nil)
        } else {
            secondaryWebView.evaluateJavaScript(buildPlayJavaScript(), completionHandler: nil)
        }
    }
    
    public func next() {
        if !queue.isEmpty {
            let nextItem = queue.removeFirst() // This pops the first element out of the queue
            print("Next item: \(nextItem)")
        } else {
            print("Queue is empty.")
        }
    }
//        
//    public func previous() {
//        if index > 0 {
//            index -= 1
//        } else {
//            print("Reached the beginning of the queue.")
//        }
//    }
}

