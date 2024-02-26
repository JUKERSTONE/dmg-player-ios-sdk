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
    // Implement the delegate methods here...
}


