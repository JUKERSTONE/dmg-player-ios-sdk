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
                        print(data, "here")
                        do {
                            let responseData = try JSONDecoder().decode(ResponseData.self, from: data)
                            if let videoURL = URL(string: responseData.url) {
                                self?.loadVideoInActiveWebView(url: videoURL)
                            } else {
                                print("Invalid video URL")
                            }
                        } catch {
                            print("Error decoding data: \(error)")
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
        if message.name == "videoEnded", let messageBody = message.body as? String, messageBody == "ended" {
            DispatchQueue.main.async {
                self.switchActiveAndInactiveWebViews()
            }
        }
    }
    
    private func switchActiveAndInactiveWebViews() {
        // Swap the references
        (activeWebView, inactiveWebView) = (inactiveWebView, activeWebView)
        
        // Load next video in the new activeWebView if necessary
        // You may also want to mute and pause the new inactiveWebView here
        // This is just a placeholder call; implement based on your app's logic
        muteAndPause(webView: inactiveWebView)
        
        // Load next video or perform other setup for the new active web view
    }
    
    private func muteAndPause(webView: WKWebView) {
        let script = "document.querySelector('video').muted = true; document.querySelector('video').pause();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
//    public func playNow(isrc: String) {
//        // Determine which webview is currently active and use it to play the requested ISRC
//        let apiService = APIService.shared
//        let urlString = "https://europe-west1-trx-traklist.cloudfunctions.net/TRX_DEVELOPER/trx/music/\(isrc)"
//        print(urlString)
//        guard let url = URL(string: urlString) else {
//            print("Invalid URL")
//            return
//        }
//        
//        apiService.fetchData(from: url) { [weak self] result in
//            guard let self = self else { return }
//            
//            switch result {
//            case .success(let data):
//                do {
//                    let responseData = try JSONDecoder().decode(ResponseData.self, from: data)
//                    DispatchQueue.main.async {
//                        // Load the video in the active webview
//                        self.activeWebView.load(URLRequest(url: responseData.trak.youtube))
//                        
//                        // Prepare the next video in the queue by preloading it in the inactive webview
//                        if let nextIsrc = self.queue.first {
//                            self.preloadNextVideo(isrc: nextIsrc)
//                        }
//                    }
//                } catch {
//                    print("Error decoding data: \(error)")
//                }
//            case .failure(let error):
//                print("Error fetching data: \(error)")
//            }
//        }
//    }
    
    private func preloadNextVideo(isrc: String) {
            // Similar logic to playNow, but for the inactive webview
            // This function should be called after a video is loaded in the active webview
            // to prepare the next video in the inactive webview
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
        // Inject JavaScript here after page load
        let jsCode = """
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
        webView.evaluateJavaScript(jsCode, completionHandler: nil)
    }
    
    // Implement other WKNavigationDelegate methods as needed
}


struct ResponseData: Decodable {
    let url: String
}

