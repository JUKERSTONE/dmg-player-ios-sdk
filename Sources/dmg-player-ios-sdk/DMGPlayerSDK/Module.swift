/**
 Module.swift
 © 2024 Jukerstone. All rights reserved.
 */

import SwiftUI
import WebKit
import AVFoundation

@available(iOS 13.0, *)
public class DMGPlayerSDK: NSObject, ObservableObject, WKScriptMessageHandler {
    
    public var index: Int
    public var isPaused: Bool
    public var buffer: [URL] = []
    public var isPictureBuffer: Bool
    public var foregroundPrimaryBuffer: WKWebView
    public var foregroundSecondaryBuffer: WKWebView
    
    @Published var queue: [String] = []
    @Published var pictureCurrentTime : Double
    @Published var isForeground: Bool = false
    @Published var isBufferActive: Bool = false
    @Published var isPrimaryActive: Bool = true
    @Published var hasLoadedNextRunner: Bool = false
    @Published var isPrimaryRunnerActive: Bool = true
    @Published var hasPreloadedNextWebview: Bool = true
    
    public override init() {
        self.index = 0
        self.queue = []
        self.buffer = []
        self.isPaused = false
        self.isBufferActive = false
        self.isPrimaryActive = true
        self.isPictureBuffer = false
        self.hasLoadedNextRunner = false
        self.isPrimaryRunnerActive = true
        self.pictureCurrentTime = 0
        self.foregroundPrimaryBuffer = WKWebView()
        self.foregroundSecondaryBuffer = WKWebView()

        super.init()
        
        configureAudioSession()
        
        let preferences = WKPreferences()
        let config = WKWebViewConfiguration()
        let bkConfig = WKWebViewConfiguration()
        
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "player")
        
        config.preferences = preferences
        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptEnabled = true
        config.allowsPictureInPictureMediaPlayback = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        bkConfig.preferences = preferences
        bkConfig.userContentController = userContentController
        bkConfig.allowsInlineMediaPlayback = true
        bkConfig.preferences.javaScriptEnabled = true
        bkConfig.allowsPictureInPictureMediaPlayback = true
        bkConfig.mediaTypesRequiringUserActionForPlayback = []
        bkConfig.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        self.foregroundSecondaryBuffer = WKWebView(frame: .zero, configuration: config)
        self.foregroundPrimaryBuffer = WKWebView(frame: .zero, configuration: config)
    
        self.foregroundSecondaryBuffer.navigationDelegate = self
        self.foregroundPrimaryBuffer.navigationDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func appMovedToBackground() {
        isForeground = false
    }
    
    public func playNow(urlString: String) {
        let apiService = APIService.shared
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        self.loadPrimaryBuffer(url: url)
    }
    
    public func jukeNow(isrc: String) {
            self.isBufferActive = false
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
                                self?.loadPrimaryBuffer(url: videoURL)
                            } else {
                            	self?.loadSecondaryBuffer(url: videoURL)
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
            foregroundPrimaryBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: nil)
        } else {
            foregroundSecondaryBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: nil)
        }
    }
    
    public func resume() {
        if isPrimaryActive {
            foregroundPrimaryBuffer.evaluateJavaScript(buildPlayJavaScript(), completionHandler: nil)
        } else {
            foregroundSecondaryBuffer.evaluateJavaScript(buildPlayJavaScript(), completionHandler: nil)
        }
    }
    
    public func next() {
        if index < queue.count - 1 {
            let nextIndex = index + 1
            let isrc = queue[nextIndex]
            
            jukeNow(isrc: isrc)
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

