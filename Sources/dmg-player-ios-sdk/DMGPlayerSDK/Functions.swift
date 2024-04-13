// Functions.swift

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
    }
    
    func loadBackgroundBuffer(url: URL) {

        let request = URLRequest(url: url)
        pictureBuffer.load(request)
        backgroundBuffer.load(request)
        // let javaScriptString = "window.location.href = '\(url)';"
        // pictureBuffer.evaluateJavaScript(javaScriptString) { result, error in
        //     if let error = error {
        //         print("Error injecting the 'load' event listener: \(error.localizedDescription)")
        //     } else {
        //         print("JavaScript executed successfully in foregroundr.")
        //     }
        // }
        
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
        // Construct the JavaScript string to seek the video to newTime
        let jsString = "document.querySelector('video').currentTime = \(time);"
        // Evaluate the JavaScript in the WKWebView
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
                backgroundBuffer.evaluateJavaScript(buildActiveJavaScript(), completionHandler: { _, error in
                    if let error = error {
                        print("Error during Java1Script execution: \(error.localizedDescription)")
                    } else {
                        print("JavaScript executed successfully in foreground.")
                    }
                })
                
                self.isFreeRunning = true
            }
            
            if self.index < self.queue.count - 1 {
                self.index += 1
            } else {
                print("Index is at the end of the queue")
            }
            
           self.isBufferActive = true
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
                            
                            let nextUp = urls[1]
                            self.buffer = urls
                                
                            if self.isBufferActive == false {
                                self.loadBackgroundBuffer(url: nextUp)
                            }
                            
                            if self.isPrimaryActive {
                                self.loadSecondaryBuffer(url: nextUp)
                            } else {
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
