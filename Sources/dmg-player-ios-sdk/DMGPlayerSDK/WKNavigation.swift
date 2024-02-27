// WKNavigation.swift

import SwiftUI
import WebKit

// Make sure to conform to WKNavigationDelegate if needed.
@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        let jsCodeCommon = """
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
                window.webkit.messageHandlers.player.postMessage(JSON.stringify({
                    eventType: 'videoProgress',
                    data: (window.trakStarVideo.currentTime / window.trakStarVideo.duration) * 100
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
        
        if isPrimaryActive == true {
            let jsCodeActive = """
                // Unmute and play the video
                window.trakStarVideo.muted = false;
                window.trakStarVideo.play();
            """
            let jsCodeInactive = """
                // Unmute and play the video
                window.trakStarVideo.muted = true;
                window.trakStarVideo.pause();
            """
            let jsCode = jsCodeCommon + jsCodeActive
            let jsCode2 = jsCodeCommon + jsCodeInactive
            primaryWebView.evaluateJavaScript(jsCode, completionHandler: nil)
            secondaryWebView.evaluateJavaScript(jsCode2, completionHandler: nil)
        } else {
            let jsCodeActive = """
                // Unmute and play the video
                window.trakStarVideo.muted = false;
                window.trakStarVideo.play();
            """
            let jsCodeInactive = """
                // Unmute and play the video
                window.trakStarVideo.muted = true;
                window.trakStarVideo.pause();
            """
            let jsCode = jsCodeCommon + jsCodeActive
            let jsCode2 = jsCodeCommon + jsCodeInactive
    
            primaryWebView.evaluateJavaScript(jsCode2, completionHandler: nil)
            secondaryWebView.evaluateJavaScript(jsCode, completionHandler: nil)
        }
        
        if isPrimaryActive == true && webView == primaryWebView {
            let jsCodeInactive = """
            if (window.trakStarVideo) {
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
            } else {
                const message = {
                    eventType: 'enablePiP',
                    data: 'No video element found.'
                };
                window.webkit.messageHandlers.player.postMessage(JSON.stringify(message));
            };
            """
            
            let jsCode = jsCodeCommon + jsCodeInactive
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        } else if isPrimaryActive == false && webView == secondaryWebView {
            let jsCodeInactive = """
            if (window.trakStarVideo) {
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
            } else {
                const message = {
                    eventType: 'enablePiP',
                    data: 'No video element found.'
                };
                window.webkit.messageHandlers.player.postMessage(JSON.stringify(message));
            };
            """
            
            let jsCode = jsCodeCommon + jsCodeInactive
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        }
    }
}



