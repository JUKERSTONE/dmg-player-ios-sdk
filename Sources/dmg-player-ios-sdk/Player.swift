import SwiftUI
import WebKit


// TrackPlayerSDK.swift
public class TrackPlayerSDK: NSObject {
    public var webView: WKWebView

    public override init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.webView.navigationDelegate = self
    }
    
    public func playNow(track: Track) {
        webView.load(URLRequest(url: track.url))
    }
}

// Make sure to conform to WKNavigationDelegate if needed.
extension TrackPlayerSDK: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject JavaScript here after page load
        let jsCode = """
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
              }
              true;
        """
        webView.evaluateJavaScript(jsCode, completionHandler: nil)
    }
    
    // Implement other WKNavigationDelegate methods as needed
}


