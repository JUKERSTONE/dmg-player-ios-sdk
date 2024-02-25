import Foundation
import WebKit

public class TrackPlayerSDK: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    
    public override init() {
        super.init()
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView?.navigationDelegate = self
    }
    
    public func playNow(track: Track) {
        guard let webView = webView else { return }
        webView.load(URLRequest(url: track.url))
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
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
}
