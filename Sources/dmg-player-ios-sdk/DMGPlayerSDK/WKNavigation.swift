// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject the common JavaScript code into both web views
        let jsCodeCommon = buildCommonJavaScript()
        
        // Evaluate JavaScript based on which web view is active
        if isPrimaryActive {
            primaryWebView.evaluateJavaScript(jsCodeCommon + buildActiveJavaScript(), completionHandler: nil)
//            secondaryWebView.evaluateJavaScript(jsCodeCommon + buildInactiveJavaScript(), completionHandler: nil)
            secondaryWebView.loadHTMLString("<html><html>", baseURL: nil)
        } else {
//            primaryWebView.evaluateJavaScript(jsCodeCommon + buildInactiveJavaScript(), completionHandler: nil)
            primaryWebView.loadHTMLString("<html><html>", baseURL: nil)
            secondaryWebView.evaluateJavaScript(jsCodeCommon + buildActiveJavaScript(), completionHandler: nil)
        }
        
        // Additional code if needed for Picture in Picture or other features
    }
    
    private func buildCommonJavaScript() -> String {
        // JavaScript code that is common to both active and inactive web views
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
        
        return jsCodeCommon
    }
    
    private func buildActiveJavaScript() -> String {
        // JavaScript code to unmute and play the video
        return """
        // Unmute and play the video
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
    
    private func buildInactiveJavaScript() -> String {
        // JavaScript code to mute and pause the video
        return """
        // Mute and pause the video
        window.trakStarVideo.muted = true;
        window.trakStarVideo.pause();
        """
    }
}
