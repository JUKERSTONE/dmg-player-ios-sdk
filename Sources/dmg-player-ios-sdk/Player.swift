import SwiftUI
import WebKit


// TrackPlayerSDK.swift
@available(iOS 13.0, *)
public class TrackPlayerSDK: NSObject, ObservableObject, WKScriptMessageHandler {
    public var activeWebView: WKWebView
    public var inactiveWebView: WKWebView
    private var index: Int = 0
    @Published var nowPlaying: String = "" // The current playing ISRC
    @Published var queue: [String] = [] // The queue of ISRCs
    
    public override init() {
        // Initialize all properties first
        self.index = 0
        self.nowPlaying = ""
        self.queue = []
        // Initialize the WebViews with a temporary value
        self.activeWebView = WKWebView()
        self.inactiveWebView = WKWebView()

        // Now call super.init()
        super.init()

        // After super.init, you can configure your WebViews properly
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "videoEnded")
        userContentController.add(self, name: "videoCurrentTime")
        config.userContentController = userContentController

        // Properly initialize the WebViews with the configuration
        self.activeWebView = WKWebView(frame: .zero, configuration: config)
        self.inactiveWebView = WKWebView(frame: .zero, configuration: config)
        self.activeWebView.navigationDelegate = self
        self.inactiveWebView.navigationDelegate = self

        // It's safe to use 'self' here
        setupVideoEndListener(webView: activeWebView)
        setupVideoEndListener(webView: inactiveWebView)
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
//                        print(data, "here")
//                        do {
//                            let responseData = try JSONDecoder().decode(ResponseData.self, from: data)
//                            if let videoURL = URL(string: responseData.url) {
//                                self?.loadVideoInActiveWebView(url: videoURL)
//                            } else {
//                                print("Invalid video URL")
//                            }
//                        } catch {
//                            print("Error decoding data: \(error)")
//                        }
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
                    
                        // Load the URL in the WebView
                        DispatchQueue.main.async { [weak self] in
                            self?.loadVideoInActiveWebView(url: videoURL)

                        }
                    case .failure(let error):
                        print("Error fetching data: \(error)")
                    }
                }
            }
    }
    
    private func loadVideoInActiveWebView(url: URL) {
            let request = URLRequest(url: url)
            activeWebView.load(request)
        }
    
    private func setupVideoEndListener(webView: WKWebView) {
        let script = "var videos = document.querySelectorAll('video'); for (var i = 0; i < videos.length; i++) { videos[i].onended = function() { window.webkit.messageHandlers.videoEnded.postMessage('ended'); }; }"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoEnded" {
            if let messageBody = message.body as? String, messageBody == "ended" {
                DispatchQueue.main.async {
                    self.switchActiveAndInactiveWebViews()
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
                    self?.loadVideoInInactiveWebView(url: videoURL)
                    
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        }
    }

    private func loadVideoInInactiveWebView(url: URL) {
        let request = URLRequest(url: url)
        inactiveWebView.load(request)
        
        // Execute JavaScript to mute and pause the video
        let script = """
            var video = document.querySelector('video');
            if (video) {
                video.muted = true;
                video.pause();
            }
        """
        inactiveWebView.evaluateJavaScript(script, completionHandler: nil)
    }

    
    private func setupVideoProgressListener(webView: WKWebView) {
        let script = """
            window.trakStarVideo.addEventListener('timeupdate', () => {
                window.webkit.messageHandlers.videoProgress.postMessage({
                    eventType: 'videoProgress',
                    data: (window.trakStarVideo.currentTime / window.trakStarVideo.duration) * 100
                });
            });
        """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    
    
    private func switchActiveAndInactiveWebViews() {
        // Mute and pause the active player
        muteAndPause(webView: activeWebView)
        
        // Swap the references
        (activeWebView, inactiveWebView) = (inactiveWebView, activeWebView)
        
        // Play the newly active player
        playActiveWebView()
        
        // Reset the index for the queue
        index = (index + 1) % queue.count
        
    }

    private func playActiveWebView() {
        // Unmute and play the video in the new activeWebView
        let script = "document.querySelector('video').muted = false; document.querySelector('video').play();"
        activeWebView.evaluateJavaScript(script, completionHandler: nil)
    }

    
    private func muteAndPause(webView: WKWebView) {
        let script = "document.querySelector('video').muted = true; document.querySelector('video').pause();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func preloadNextVideo(isrc: String) {
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
                    self?.loadVideoInInactiveWebView(url: videoURL)
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        }
    }
        
        private func loadVideoInInactiveWebView(url: URL) {
            let request = URLRequest(url: url)
            inactiveWebView.load(request)
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
    
//    public func removeFromQueue(track: Track) {
//        webView.load(URLRequest(url: track.url))
//    }
    
}

// Make sure to conform to WKNavigationDelegate if needed.
@available(iOS 13.0, *)
extension TrackPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject JavaScript for both active and inactive web views
        let jsCodeCommon = """
            if (!window.trakStarVideo) {
                window.trakStarVideo = document.getElementsByTagName('video')[0];
            }
            
            if (window.trakStarVideo) {
                window.trakStarVideo.requestPictureInPicture().then(() => {
                    const message = {
                        eventType: 'enablePiP',
                        data: 'PiP initiated successfully.'
                    };
                    window.ReactNativeWebView.postMessage(JSON.stringify(message));
                }).catch(error => {
                    const message = {
                        eventType: 'enablePiP',
                        data: 'PiP initiation failed: ' + error.message
                    };
                    window.ReactNativeWebView.postMessage(JSON.stringify(message));
                });
            } else {
                const message = {
                    eventType: 'enablePiP',
                    data: 'No video element found.'
                };
                window.ReactNativeWebView.postMessage(JSON.stringify(message));
            };
            window.trakStarVideo = document.getElementsByTagName('video')[0];
            
            window.trakStarVideo.addEventListener('loadedmetadata', () => {
                window.ReactNativeWebView.postMessage(JSON.stringify({
                    eventType: 'videoReady',
                    data: true
                }));
            });
            
            window.trakStarVideo.addEventListener('ended', function() {
                window.ReactNativeWebView.postMessage(JSON.stringify({
                    eventType: 'videoEnded',
                    data: 100
                }));
            });
            
            window.trakStarVideo.addEventListener('timeupdate', () => {
                window.ReactNativeWebView.postMessage(JSON.stringify({
                    eventType: 'videoCurrentTime',
                    data: (window.trakStarVideo.currentTime / window.trakStarVideo.duration) * 100
                }));
            });
            
            window.trakStarVideo.addEventListener('error', function() {
                window.ReactNativeWebView.postMessage(JSON.stringify({
                    eventType: 'videoError',
                    data: 'An error occurred while trying to load the video.'
                }));
            });
            true;
        """
        
        // Check if the webView is the activeWebView
        if webView == activeWebView {
            // Inject JavaScript for the active web view
            let jsCodeActive = """
                // Unmute and play the video
                document.querySelector('video').muted = false;
                document.querySelector('video').play();
            """
            let jsCode = jsCodeCommon + jsCodeActive
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        } else {
            // Inject JavaScript for the inactive web view
            let jsCodeInactive = """
                // Mute and pause the video
                document.querySelector('video').muted = true;
                document.querySelector('video').pause();
            """
            let jsCode = jsCodeCommon + jsCodeInactive
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        }
    }

    
    // Implement other WKNavigationDelegate methods as needed
}



