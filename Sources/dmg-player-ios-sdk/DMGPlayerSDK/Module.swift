// Module.swift

import SwiftUI
import WebKit
import AVFoundation

@available(iOS 13.0, *)
public class DMGPlayerSDK: NSObject, ObservableObject, WKScriptMessageHandler {
    public var primaryWebView: WKWebView
    public var secondaryWebView: WKWebView
    public var bkPrimaryWebView: WKWebView
    public var bkSecondaryWebView: WKWebView
    public var index: Int
    public var isPaused: Bool
    public var bkConfig: WKWebViewConfiguration
    @Published var isForeground: Bool = false
    @Published var hasPreloadedNextWebview: Bool = true
    @Published var isPrimaryActive: Bool = true
    @Published var hasBkPreloadedNextWebview: Bool = true
    @Published var isBkPrimaryActive: Bool = true
    @Published var queue: [String] = []
    
    public override init() {
        self.queue = []
        self.primaryWebView = WKWebView()
        self.secondaryWebView = WKWebView()
        self.bkPrimaryWebView = WKWebView()
        self.bkSecondaryWebView = WKWebView()
        self.isPrimaryActive = true
        self.index = 0
        self.isPaused = false
        self.bkConfig = WKWebViewConfiguration()

        super.init()

        configureAudioSession()
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let preferences = WKPreferences()
        userContentController.add(self, name: "player")
        config.userContentController = userContentController
        config.preferences = preferences
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.preferences.javaScriptEnabled = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        bkConfig.userContentController = userContentController
        bkConfig.preferences = preferences
        bkConfig.allowsInlineMediaPlayback = true
        bkConfig.allowsPictureInPictureMediaPlayback = true
//        bkConfig.preferences.javaScriptEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.primaryWebView = WKWebView(frame: .zero, configuration: config)
        self.secondaryWebView = WKWebView(frame: .zero, configuration: config)
        self.bkPrimaryWebView = WKWebView(frame: .zero, configuration: bkConfig)
        self.bkSecondaryWebView = WKWebView(frame: .zero, configuration: bkConfig)
        self.primaryWebView.navigationDelegate = self
        self.secondaryWebView.navigationDelegate = self
        self.bkPrimaryWebView.navigationDelegate = self
        self.bkSecondaryWebView.navigationDelegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        isForeground = true
    }
    
    @objc private func appMovedToBackground() {
        let nextIndex = index + 1
        // Perform a bounds check for nextIndex
        guard nextIndex < queue.count else {
            print("Index out of bounds.")
            return
        }
        
        let isrc = queue[index + 1]
        
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
//                        if self?.isPrimaryActive == true {
//                            self?.loadVideoInPrimaryWebView(url: videoURL)
//                        } else {
//                            self?.loadVideoInSecondaryWebView(url: videoURL)
//                        }
                        self?.loadBkVideoInPrimaryWebView(url: videoURL)

                    }
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        }
        
        isForeground = false
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
        primaryWebView.loadHTMLString("", baseURL: nil)
        secondaryWebView.loadHTMLString("", baseURL: nil)
    }
}

