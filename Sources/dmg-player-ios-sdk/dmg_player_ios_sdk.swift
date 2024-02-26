import Foundation
import WebKit

public class TrackPlayerSDK: NSObject, WKNavigationDelegate {
    public var webView: WKWebView?
    
    public override init() {
        super.init()
        let config = WKWebViewConfiguration()
        // Configuration here, if needed...
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView?.navigationDelegate = self
    }
    
    public func playNow(track: Track) {
        guard let webView = webView else { return }
        webView.load(URLRequest(url: track.url))
    }
    
    // Implement the WKNavigationDelegate methods here...
}
