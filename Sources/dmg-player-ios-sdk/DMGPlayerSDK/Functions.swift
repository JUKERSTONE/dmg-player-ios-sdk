/**
 Functions.swift
 © 2024 Jukerstone. All rights reserved.
 */

import SwiftUI
import WebKit
import AVFAudio

@available(iOS 13.0, *)
extension DMGPlayerSDK {
    func loadRunner(webView: WKWebView) {
        if self.index < self.buffer.count - 1 {
            self.index += 1
        } else {
            print("Index is at the end of the queue")
        }
        
        let url = self.buffer[self.index]
        let javaScriptString = "window.location.href = '\(url)';"

        webView.evaluateJavaScript(javaScriptString) { result, error in
            if let error = error {
                print("Error injecting the 'load' event listener: \(error.localizedDescription)")
            } else {
                print("JavaScript executed successfully in foregroundr.")
            }
        }
        
        pictureBuffer.evaluateJavaScript(javaScriptString) { result, error in
            if let error = error {
                print("Error injecting the 'load' event listener: \(error.localizedDescription)")
            } else {
                print("JavaScript executed successfully in foregroundr.")
            }
        }
    }
    
    func loadPicture() {
        if self.index + 1 < self.buffer.count {
            let url = self.buffer[self.index + 1]
            let request = URLRequest(url: url)
            
            pictureBuffer.load(request)
            
            self.pictureCurrentTime = 0
        } else {
            // Handle the situation where self.index + 1 would be out of bounds
            // This could be resetting the index, or some other error handling
        }
    }
    
    func loadBackgroundBuffer(url: URL) {
        let request = URLRequest(url: url)
        pictureBuffer.load(request)
        backgroundBuffer.load(request)
    }
    
    func loadPrimaryBuffer(url: URL) {
        let request = URLRequest(url: url)
        foregroundPrimaryBuffer.load(request)
    }
    
    func loadSecondaryBuffer(url: URL) {
        let request = URLRequest(url: url)
        foregroundSecondaryBuffer.load(request)
    }
    
    func synchronisePictureBuffer(time : Double) {
        if self.isPictureBuffer {
            return
        }
        
        let jsString = "document.querySelector('video').currentTime = \(time);"
        
        self.pictureBuffer.evaluateJavaScript(jsString) { (result, error) in
            if let error = error {
                print("JavaScript evaluation error: \(error.localizedDescription)")
            } else {
                print("Video seeker updated to \(time) seconds.")
            }
        }
    }
    
    func play(webView: WKWebView) {
        if UIApplication.shared.applicationState == .active {
            if webView === self.foregroundPrimaryBuffer {
                print("webview is primary")
            } else if webView === self.foregroundSecondaryBuffer {
                print("webview is secondary")
            }
            webView.evaluateJavaScript(buildActiveJavaScript(), completionHandler: { _, error in
                if let error = error {
                    print("Error during JavaScript execution: \(error.localizedDescription)")
                } else {
                    print("JavaScript executed successfully in foreground.")
                }
            })
            
            if self.index < self.queue.count - 1 {
                self.index += 1
            } else {
                print("Index is at the end of the queue")
            }

               self.isBufferActive = false
        } else {
            if self.isFreeRunning == true {
                if self.index + 1 < self.buffer.count {
                    if self.isPrimaryRunnerActive {
                        self.loadRunner(webView: self.backgroundRunningPrimaryBuffer)
                        self.isPrimaryRunnerActive = false
                    } else {
                        self.loadRunner(webView: self.backgroundRunningSecondaryBuffer)
                        self.isPrimaryRunnerActive = true
                    }
                } else {
                    print("Index is out of range of the buffer array")
                }
            } else {
                print("made it")
                backgroundBuffer.evaluateJavaScript(buildActiveJavaScript(), completionHandler: { _, error in
                    if let error = error {
                        print("Error during bk play js: \(error.localizedDescription)")
                    } else {
                        print("JavaScript executed successfully for bk.")
                    }
                })
                
                self.isBufferActive = true
                self.isPictureBuffer = false
                self.isFreeRunning = true
            }
            
            if self.index < self.queue.count - 1 {
                self.index += 1
            } else {
                print("Index is at the end of the queue")
            }
        }
    }

    
    func updatedPreload(buffer: [String], index: Int) {
            let apiService = APIService.shared
            let urlString = "https://europe-west1-trx-traklist.cloudfunctions.net/TRX_DEVELOPER/trx/music/buffer"

            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }

            guard let jsonData = try? JSONSerialization.data(withJSONObject: buffer, options: []) else {
                print("Failed to serialize buffer to JSON")
                return
            }

            if let jsonString = apiService.parseJSON(from: buffer) {
                print("JSON String to be sent: \(jsonString)")
            }

            apiService.postData(to: url, body: jsonData) { result in
                switch result {
                case .success(let data):
                    if let urlStringArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                        DispatchQueue.main.async {
                            let urls = urlStringArray.compactMap { urlString -> URL? in
                                return URL(string: urlString.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
                            }
                            
                            let nextUp = urls[self.index + 1]
                            print(self.index, "check index")
                            self.buffer = urls
                                
                            if self.isBufferActive == false {
                                self.loadBackgroundBuffer(url: nextUp)
                            }
                            
                            if self.isPrimaryActive {
                                print("queue")
                                self.loadSecondaryBuffer(url: nextUp)
                            } else {
                                print("queue 1")
                                self.loadPrimaryBuffer(url: nextUp)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            print("The received data is not an array of strings.")
                        }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        print("Failed to update preload:", error)
                    }
                }
            }

        }
}

public func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print("Failed to set audio session category. Error: \(error)")
    }
}

public func buildActiveJavaScript() -> String {
    return """
    if (!window.trakStarVideo) {
        window.trakStarVideo = document.getElementsByTagName('video')[0];
    }
    
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
    """
}

public func buildInactiveJavaScript() -> String {
    return """
    window.trakStarVideo.muted = true;
    window.trakStarVideo.pause();
    """
}

public func buildPauseJavaScript() -> String {
    return """
    window.trakStarVideo.muted = true;
    window.trakStarVideo.pause();
    """
}

public func buildPlayJavaScript() -> String {
    return """
    window.trakStarVideo.muted = false;
    window.trakStarVideo.play();
    """
}

public func buildCommonJavaScript() -> String {
    return """
        if (!window.trakStarVideo) {
            window.trakStarVideo = document.getElementsByTagName('video')[0];
        }
        
        window.trakStarVideo = document.getElementsByTagName('video')[0];
        
        window.trakStarVideo.addEventListener('loadedmetadata', () => {
            window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                eventType: 'videoReady',
                data: true
            }));
        });
        
        window.trakStarVideo.addEventListener('ended', function() {
            window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                eventType: 'videoEnded',
                data: 100
            }));
        });
        
        window.trakStarVideo.addEventListener('timeupdate', () => {
            const currentTime = window.trakStarVideo.currentTime;
            const duration = window.trakStarVideo.duration;
            const progress = (currentTime / duration) * 100; // This calculates the progress percentage

            window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                eventType: 'videoProgress',
                data: {
                    currentTime: currentTime, // Current time of the video in seconds
                    duration: duration,       // Total duration of the video in seconds
                    progress: progress        // Progress percentage of the video
                }
            }));
        });
        
        window.trakStarVideo.addEventListener('error', function() {
            window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                eventType: 'videoError',
                data: 'An error occurred while trying to load the video.'
            }));
        });
        true;
    """
}
