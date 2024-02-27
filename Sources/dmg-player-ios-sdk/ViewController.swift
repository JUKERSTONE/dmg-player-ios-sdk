import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
    
    var activeWebView: WKWebView!
    var inactiveWebView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebViews()
    }

    func setupWebViews() {
        let webConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "videoEnded")
        webConfiguration.userContentController = userContentController

        activeWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        inactiveWebView = WKWebView(frame: .zero, configuration: webConfiguration)

        // Add web views to the view hierarchy and set up constraints as needed
        // For example:
        // self.view.addSubview(activeWebView)
        // self.view.addSubview(inactiveWebView)
        // ... Set up constraints or frame here ...
    }

    func preloadNextVideoInInactiveWebView(url: URL) {
        inactiveWebView.load(URLRequest(url: url))
        muteAndPause(webView: inactiveWebView)
    }

    func muteAndPause(webView: WKWebView) {
        let script = "document.querySelector('video').muted = true; document.querySelector('video').pause();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func setupVideoEndListener(webView: WKWebView) {
        let script = "var videos = document.querySelectorAll('video'); for (var i = 0; i < videos.length; i++) { videos[i].onended = function() { window.webkit.messageHandlers.videoEnded.postMessage('ended'); }; }"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoEnded", let messageBody = message.body as? String, messageBody == "ended" {
            DispatchQueue.main.async {
                self.switchActiveAndInactiveWebViews()
            }
        }
    }

    func switchActiveAndInactiveWebViews() {
        // Swap the references
        (activeWebView, inactiveWebView) = (inactiveWebView, activeWebView)

        // Prepare the new inactive web view (now active) as needed, e.g., unmute
        // This may involve loading new content, adjusting UI, etc.
        
        // Ensure the new inactive web view is muted and paused for its next video
        muteAndPause(webView: inactiveWebView)
    }
}
