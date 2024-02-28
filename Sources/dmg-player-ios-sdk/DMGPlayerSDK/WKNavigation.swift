// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(isPrimaryActive, "grgre")
        let jsCodeCommon = buildCommonJavaScript()
        webView.evaluateJavaScript(buildCommonJavaScript(), completionHandler: nil)
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
}
