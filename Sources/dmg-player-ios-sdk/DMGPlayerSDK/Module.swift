// Module.swift

import SwiftUI
import WebKit


@available(iOS 13.0, *)
public class DMGPlayerSDK: NSObject, ObservableObject, WKScriptMessageHandler {
    public var primaryWebView: WKWebView
    public var secondaryWebView: WKWebView
    public var index: Int
    @Published var hasPreloadedNextWebview: Bool = true
    @Published var isPrimaryActive: Bool = true
    @Published var queue: [String] = []
    
    public override init() {
        self.queue = []
        self.primaryWebView = WKWebView()
        self.secondaryWebView = WKWebView()
        self.index = 0

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
        print(queue)
    }
}

