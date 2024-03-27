// Module.swift

import SwiftUI
import WebKit
import AVFoundation

@available(iOS 13.0, *)
public class DMGPlayerSDK: NSObject, ObservableObject, WKScriptMessageHandler {
    
    public var index: Int
    public var isPaused: Bool
    public var buffer: [URL] = []
    public var backgroundBuffer: WKWebView
    public var foregroundPrimaryBuffer: WKWebView
    public var foregroundSecondaryBuffer: WKWebView
    public var backgroundRunningPrimaryBuffer: WKWebView
    public var backgroundRunningSecondaryBuffer: WKWebView
    @Published var isForeground: Bool = false
    @Published var hasPreloadedNextWebview: Bool = true
    @Published var hasLoadedNextRunner: Bool = false
    @Published var isPrimaryRunnerActive: Bool = true
    @Published var isPrimaryActive: Bool = true
    @Published var isFreeRunning: Bool = false
    @Published var isBufferActive: Bool = false
    @Published var queue: [String] = []
    
    public override init() {
        self.index = 0
        self.queue = []
        self.buffer = []
        self.isPaused = false
        self.isBufferActive = false
        self.isFreeRunning = false
        self.isPrimaryActive = true
        self.isPrimaryRunnerActive = true
        self.hasLoadedNextRunner = false
        self.backgroundBuffer = WKWebView()
        self.foregroundPrimaryBuffer = WKWebView()
        self.foregroundSecondaryBuffer = WKWebView()
        self.backgroundRunningPrimaryBuffer = WKWebView()
        self.backgroundRunningSecondaryBuffer = WKWebView()

        super.init()
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.foregroundPrimaryBuffer = WKWebView(frame: .zero, configuration: config)
        self.foregroundSecondaryBuffer = WKWebView(frame: .zero, configuration: config)
        self.backgroundRunningPrimaryBuffer = WKWebView(frame: .zero, configuration: bkConfig)
        self.backgroundRunningSecondaryBuffer = WKWebView(frame: .zero, configuration: bkConfig)
        self.backgroundBuffer = WKWebView(frame: .zero, configuration: config)
        self.foregroundPrimaryBuffer.navigationDelegate = self
        self.foregroundSecondaryBuffer.navigationDelegate = self
        self.backgroundBuffer.navigationDelegate = self
        self.backgroundRunningPrimaryBuffer.navigationDelegate = self
        self.backgroundRunningSecondaryBuffer.navigationDelegate = self
        
        if let url = URL(string: "https://google.com") {
            let request = URLRequest(url: url)
            self.backgroundRunningPrimaryBuffer.load(request)
            self.backgroundRunningSecondaryBuffer.load(request)
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

        if isBufferActive {
            // isfreeloading?
            backgroundBuffer.evaluateJavaScript(jsCode, completionHandler: { result, error in
                if let error = error {
                    print("JavaScript evaluation error: \(error.localizedDescription)")
                } else {
                    print("JavaScript evaluated successfully")
                }
            })
        }
    }
    
    @objc private func appMovedToBackground() {
        isForeground = false
        print("is Background")
    }
    
    public func playNow(isrc: String) {
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
        if isBufferActive {
            if isFreeRunning {
                // isFreeloading primary?
                backgroundRunningPrimaryBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: { result, error in
                    if let error = error {
                        print("JavaScript evaluation error: \(error.localizedDescription)")
                    } else {
                        print("JavaScript evaluated successfully")
                    }
                })
            } else {
                backgroundBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: { result, error in
                    if let error = error {
                        print("JavaScript evaluation error: \(error.localizedDescription)")
                    } else {
                        print("JavaScript evaluated successfully")
                    }
                })
            }
        } else if isPrimaryActive {
            foregroundPrimaryBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: nil)
        } else {
            foregroundSecondaryBuffer.evaluateJavaScript(buildPauseJavaScript(), completionHandler: nil)
        }
    }
    
    public func resume() {
        if isBufferActive {
            if isFreeRunning {
                // isFreeloading primary?
                
                backgroundRunningPrimaryBuffer.evaluateJavaScript(buildPlayJavaScript(), completionHandler: { result, error in
                    if let error = error {
                        print("JavaScript evaluation error: \(error.localizedDescription)")
                    } else {
                        print("JavaScript evaluated successfully")
                    }
                })
            } else {
                backgroundBuffer.evaluateJavaScript(buildPlayJavaScript(), completionHandler: { result, error in
                    if let error = error {
                        print("JavaScript evaluation error: \(error.localizedDescription)")
                    } else {
                        print("JavaScript evaluated successfully")
                    }
                })
            }
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
        backgroundBuffer.loadHTMLString("", baseURL: nil)
        backgroundRunningPrimaryBuffer.loadHTMLString("", baseURL: nil)
        backgroundRunningSecondaryBuffer.loadHTMLString("", baseURL: nil)
    }
}

