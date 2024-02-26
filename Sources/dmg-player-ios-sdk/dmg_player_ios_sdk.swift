import Foundation
import SwiftUI // This import is necessary for SwiftUI-specific types
import WebKit

public class TrackPlayerSDK: NSObject, WKNavigationDelegate {
    public var webView: WKWebView?
    public var currentTrack: Track?
    
    public override init() {
        super.init()
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView?.navigationDelegate = self
    }
    
    public func playNow(track: Track) {
        currentTrack = track
        guard let webView = webView else { return }
        webView.load(URLRequest(url: track.url))
    }
    
    public func makeUIView() -> WKWebView {
        return webView ?? WKWebView()
    }
    
    public func updateUIView(_ uiView: WKWebView) {
        if let track = currentTrack {
            uiView.load(URLRequest(url: track.url))
        }
    }
    
    // WKNavigationDelegate methods...
}


