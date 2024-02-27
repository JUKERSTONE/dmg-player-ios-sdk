import SwiftUI
import WebKit

// Make sure to conform to WKNavigationDelegate if needed.
@available(iOS 13.0, *)
extension TrackPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        print(activeWebView)
        print(inactiveWebView)
        
        // Inject JavaScript for both active and inactive web views
        let jsCodeCommon = """
            if (!window.trakStarVideo) {
                window.trakStarVideo = document.getElementsByTagName('video')[0];
            }
            
            if (window.trakStarVideo) {
                window.trakStarVideo.requestPictureInPicture().then(() => {
                    const message = {
                        eventType: 'enablePiP',
                        data: 'PiP initiated successfully.'
                    };
                    window.ReactNativeWebView.postMessage(JSON.stringify(message));
                }).catch(error => {
                    const message = {
                        eventType: 'enablePiP',
                        data: 'PiP initiation failed: ' + error.message
                    };
                    window.ReactNativeWebView.postMessage(JSON.stringify(message));
                });
            } else {
                const message = {
                    eventType: 'enablePiP',
                    data: 'No video element found.'
                };
                window.ReactNativeWebView.postMessage(JSON.stringify(message));
            };
            window.trakStarVideo = document.getElementsByTagName('video')[0];
            
            window.trakStarVideo.addEventListener('loadedmetadata', () => {
                window.ReactNativeWebView.postMessage(JSON.stringify({
                    eventType: 'videoReady',
                    data: true
                }));
            });
            
            window.trakStarVideo.addEventListener('ended', function() {
                window.ReactNativeWebView.postMessage(JSON.stringify({
                    eventType: 'videoEnded',
                    data: 100
                }));
            });
            
            window.trakStarVideo.addEventListener('timeupdate', () => {
                window.ReactNativeWebView.postMessage(JSON.stringify({
                    eventType: 'videoCurrentTime',
                    data: (window.trakStarVideo.currentTime / window.trakStarVideo.duration) * 100
                }));
            });
            
            window.trakStarVideo.addEventListener('error', function() {
                window.ReactNativeWebView.postMessage(JSON.stringify({
                    eventType: 'videoError',
                    data: 'An error occurred while trying to load the video.'
                }));
            });
            true;
        """
        
        // Check if the webView is the activeWebView
        if webView == activeWebView {
            // Inject JavaScript for the active web view
            let jsCodeActive = """
                // Unmute and play the video
                document.querySelector('video').muted = false;
                document.querySelector('video').play();
            """
            let jsCode = jsCodeCommon + jsCodeActive
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        } else {
            // Inject JavaScript for the inactive web view
            let jsCodeInactive = """
                // Mute and pause the video
                document.querySelector('video').muted = true;
                document.querySelector('video').pause();
            """
            let jsCode = jsCodeCommon + jsCodeInactive
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        }
    }

    
    // Implement other WKNavigationDelegate methods as needed
}



