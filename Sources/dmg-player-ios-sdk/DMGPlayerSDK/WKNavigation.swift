// WKNavigation.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let jsCodeCommon = buildCommonJavaScript()
        
        if webView == backgroundWebView {
            print("loaded bk")
            
            if UIApplication.shared.applicationState == .active {
                // App is in the foreground
                webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: { (result, error) in
                    if let error = error {
                        print("Error during JavaScript execution: \(error.localizedDescription)")
                    } else {
                        print("JavaScript executed successfully in the foreground.")
                    }
                })
            }
        }

        
        if self.isPrimaryActive && webView == primaryWebView {
            webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
        } else if self.isPrimaryActive && webView == secondaryWebView {
            webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
        } else if !self.isPrimaryActive && webView == primaryWebView {
            webView.evaluateJavaScript(buildCommonJavaScript() + buildInactiveJavaScript(), completionHandler: nil)
        } else if !self.isPrimaryActive && webView == secondaryWebView {
            webView.evaluateJavaScript(buildCommonJavaScript() + buildActiveJavaScript(), completionHandler: nil)
        }
        
    }
    
    
    private func buildCommonJavaScript() -> String {
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
