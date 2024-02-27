import SwiftUI
import WebKit


// TrackPlayerSDK.swift
@available(iOS 13.0, *)
public class TrackPlayerSDK: NSObject, ObservableObject, WKScriptMessageHandler {
    public var primaryWebView: WKWebView
    public var secondaryWebView: WKWebView
    @Published var isPrimaryActive: Bool = true
    @Published var index: Int = 0
    @Published var nowPlaying: String = ""
    @Published var queue: [String] = []
    
    public override init() {
        self.index = 0
        self.nowPlaying = ""
        self.queue = []
        self.primaryWebView = WKWebView()
        self.secondaryWebView = WKWebView()

        super.init()

        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "videoEnded")
        userContentController.add(self, name: "videoCurrentTime")
        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        
        self.primaryWebView = WKWebView(frame: .zero, configuration: config)
        self.secondaryWebView = WKWebView(frame: .zero, configuration: config)
        self.primaryWebView.navigationDelegate = self
        self.secondaryWebView.navigationDelegate = self

        setupVideoEndListener(webView: primaryWebView)
        setupVideoEndListener(webView: secondaryWebView)
    }

    
    public func playNow(isrc: String) {
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
                        
                        print(urlStringWithQuotes)
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
        queue.insert(isrc, at: 0)
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
    
    private func loadVideoInPrimaryWebView(url: URL) {
            let request = URLRequest(url: url)
            primaryWebView.load(request)
    }
    
    private func loadVideoInSecondaryWebView(url: URL) {
            let request = URLRequest(url: url)
            secondaryWebView.load(request)
    }
    
    private func setupVideoEndListener(webView: WKWebView) {
        let script = "var videos = document.querySelectorAll('video'); for (var i = 0; i < videos.length; i++) { videos[i].onended = function() { window.webkit.messageHandlers.videoEnded.postMessage('ended'); }; }"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoEnded" {
            if let messageBody = message.body as? String, messageBody == "ended" {
                DispatchQueue.main.async {
                    self.switchPlayer(toSecondary: !self.isPrimaryActive)
                }
            }
        } else if message.name == "videoCurrentTime" {
            if let messageBody = message.body as? [String: Any], let eventType = messageBody["eventType"] as? String {
                if eventType == "videoCurrentTime" {
                    // Handle video progress message
                    if let progressData = messageBody["data"] as? Double {
                        // Process the progress data
                        if progressData > 80.0 {
                            // Preload the inactive web view
                            preloadInactiveWebView()
                        }
                    }
                }
            }
        }
    }
    
    private func preloadInactiveWebView() {
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
                            self?.loadVideoInPrimaryWebView(url: videoURL)
                        } else {
                            self?.loadVideoInSecondaryWebView(url: videoURL)
                        }
                    
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        }
    }


    
//    private func setupVideoProgressListener(webView: WKWebView) {
//        let script = """
//            window.trakStarVideo.addEventListener('timeupdate', () => {
//                window.webkit.messageHandlers.videoProgress.postMessage({
//                    eventType: 'videoProgress',
//                    data: (window.trakStarVideo.currentTime / window.trakStarVideo.duration) * 100
//                });
//            });
//        """
//        webView.evaluateJavaScript(script, completionHandler: nil)
//    }

    
    
    private func switchPlayer(toSecondary : Bool) {
        
        // Mute and pause the active player
        muteAndPause(webView: primaryWebView)
        
        primaryWebView.loadHTMLString("<html></html>", baseURL: nil)
        
        isPrimaryActive = false
        
        // Play the newly active player
//        let currentISRC = queue[index] // Get the isrc at the current index of the queue
//        playNow(isrc: currentISRC)

        if !queue.isEmpty {
            queue.removeFirst()
        }
        
        // Reset the index for the queue
        index = (index + 1) % queue.count
        
    }

    private func playActiveWebView() {
        // Unmute and play the video in the new activeWebView
        let script = "window.trakStarVideo.muted = false; window.trakStarVideo.play();"
        secondaryWebView.evaluateJavaScript(script, completionHandler: nil)
    }

    
    private func muteAndPause(webView: WKWebView) {
        let script = "window.trakStarVideo.muted = true; window.trakStarVideo.pause();"
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

