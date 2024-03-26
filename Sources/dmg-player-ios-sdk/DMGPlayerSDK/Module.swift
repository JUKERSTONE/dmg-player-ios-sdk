// Module.swift

import SwiftUI
import WebKit
import AVFoundation

@available(iOS 13.0, *)
public class DMGPlayerSDK: NSObject, ObservableObject, WKScriptMessageHandler {
    public var foregroundPrimaryBuffer: WKWebView
    public var foregroundSecondaryBuffer: WKWebView
    public var freeloadingBuffer: WKWebView
    public var backgroundPrimaryBuffer: WKWebView
//    public var backgroundSecondaryBuffer: WKWebView
    public var index: Int
    public var isPaused: Bool
    public var buffer: [URL] = []
    @Published var isForeground: Bool = false
    @Published var hasPreloadedNextWebview: Bool = true
    @Published var isPrimaryActive: Bool = true
    @Published var isBkPrimaryActive: Bool = true
    @Published var isFreeloading: Bool = false
    @Published var isBkActive: Bool = false
    @Published var hasBkPreloadedNextWebview: Bool = true
    @Published var queue: [String] = []
    
    public override init() {
        self.queue = []
        self.buffer = []
        self.foregroundPrimaryBuffer = WKWebView()
        self.foregroundSecondaryBuffer = WKWebView()
        self.freeloadingBuffer = WKWebView()
        self.backgroundPrimaryBuffer = WKWebView()
//        self.backgroundSecondaryBuffer = WKWebView()
        self.isPrimaryActive = true
        self.isBkPrimaryActive = true
        self.isBkActive = false
        self.isFreeloading = false
        self.index = 0
        self.isPaused = false

        super.init()

        configureAudioSession()
        let config = WKWebViewConfiguration()
        let bkConfig = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let preferences = WKPreferences()
        userContentController.add(self, name: "player")
        config.userContentController = userContentController
        config.preferences = preferences
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        bkConfig.userContentController = userContentController
        bkConfig.preferences = preferences
        bkConfig.preferences.javaScriptEnabled = true
        bkConfig.preferences.javaScriptCanOpenWindowsAutomatically = true
        bkConfig.allowsInlineMediaPlayback = true
        bkConfig.allowsPictureInPictureMediaPlayback = true
        bkConfig.mediaTypesRequiringUserActionForPlayback = []
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.foregroundPrimaryBuffer = WKWebView(frame: .zero, configuration: config)
        self.foregroundSecondaryBuffer = WKWebView(frame: .zero, configuration: config)
        self.backgroundPrimaryBuffer = WKWebView(frame: .zero, configuration: config)
//        self.backgroundSecondaryBuffer = WKWebView(frame: .zero, configuration: config)
        self.freeloadingBuffer = WKWebView(frame: .zero, configuration: bkConfig)
        self.foregroundPrimaryBuffer.navigationDelegate = self
        self.foregroundSecondaryBuffer.navigationDelegate = self
        self.backgroundPrimaryBuffer.navigationDelegate = self
//        self.backgroundSecondaryBuffer.navigationDelegate = self
        self.freeloadingBuffer.navigationDelegate = self
        
        if let url = URL(string: "https://google.com") {
            let request = URLRequest(url: url)
            self.freeloadingBuffer.load(request)
            self.backgroundSecondaryBuffer.load(request)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        isForeground = true
        print("is Foreground")
        
        let jsCode = """
            if (!window.trakStarVideo) {
                window.trakStarVideo = document.getElementsByTagName('video')[0];
            }

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

        if isBkActive {
            backgroundPrimaryBuffer.evaluateJavaScript(jsCode, completionHandler: { result, error in
                if let error = error {
                    print("JavaScript evaluation error: \(error.localizedDescription)")
                } else {
                    print("JavaScript evaluated successfully")
                }
            })
        }
//            else {
//            bkSecondaryWebView.evaluateJavaScript(jsCode, completionHandler: { result, error in
//                if let error = error {
//                    print("JavaScript evaluation error: \(error.localizedDescription)")
//                } else {
//                    print("JavaScript evaluated successfully")
//                }
//            })
//        }
            
    }
    
    @objc private func appMovedToBackground() {
        isForeground = false
        print("is Background")
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure the audio session: \(error.localizedDescription)")
        }
    }

    
    public func playNow(isrc: String) {
            self.isBkActive = false
            queue.insert(isrc, at: 0)
        
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
        print(isBkActive, ": bk")
        if isBkActive {
            backgroundPrimaryBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: { result, error in
                if let error = error {
                    print("JavaScript evaluation error: \(error.localizedDescription)")
                } else {
                    print("JavaScript evaluated successfully")
                }
            })
        } else if isPrimaryActive {
            foregroundPrimaryBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: nil)
        } else {
            foregroundSecondaryBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: nil)
        }
    }
    
    public func resume() {
        print(isBkActive, ": bk1")
        if isBkActive {
            backgroundPrimaryBuffer.evaluateJavaScript(buildPlayJavaScript(), completionHandler: { result, error in
                if let error = error {
                    print("JavaScript evaluation error1: \(error.localizedDescription)")
                } else {
                    print("JavaScript evaluated successfully1")
                }
            })
        } else if isPrimaryActive {
            foregroundPrimaryBuffer.evaluateJavaScript(buildPlayJavaScript(), completionHandler: nil)
        } else {
            foregroundSecondaryBuffer.evaluateJavaScript(buildPlayJavaScript(), completionHandler: nil)
        }
    }
    
    public func next() {
        if index < queue.count - 1 {
            let nextIndex = index + 1
            let isrc = queue[nextIndex]
            
            playNow(isrc: isrc)
            index = nextIndex
            queue.remove(at: nextIndex)
        } else {
            stop()
        }
    }
       
    public func stop() {
        foregroundPrimaryBuffer.loadHTMLString("", baseURL: nil)
        foregroundSecondaryBuffer.loadHTMLString("", baseURL: nil)
    }
}

