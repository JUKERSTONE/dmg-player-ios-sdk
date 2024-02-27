import UIKit
import SwiftUI
import WebKit

@available(iOS 13.0, *)
public class ViewController: UIViewController, WKScriptMessageHandler {
    
    public var activeWebView: WKWebView!
    public var inactiveWebView: WKWebView!
    public var sdk: TrackPlayerSDK  // Add this property
       
       // Modify the initializer to accept TrackPlayerSDK
       public init(sdk: TrackPlayerSDK) {
           self.sdk = sdk
           super.init(nibName: nil, bundle: nil)
       }
       
       // Add required initializer for UIViewController
       required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebViews()
    }

    public func setupWebViews() {
        let webConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "videoEnded")
        webConfiguration.userContentController = userContentController

        activeWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        inactiveWebView = WKWebView(frame: .zero, configuration: webConfiguration)

        self.view.addSubview(activeWebView)
        self.view.addSubview(inactiveWebView)
        // Set up constraints or frame here
    }

    public func preloadNextVideoInInactiveWebView(url: URL) {
        inactiveWebView.load(URLRequest(url: url))
        muteAndPause(webView: inactiveWebView)
    }

    public func muteAndPause(webView: WKWebView) {
        let script = "document.querySelector('video').muted = true; document.querySelector('video').pause();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    public func setupVideoEndListener(webView: WKWebView) {
        let script = "var videos = document.querySelectorAll('video'); for (var i = 0; i < videos.length; i++) { videos[i].onended = function() { window.webkit.messageHandlers.videoEnded.postMessage('ended'); }; }"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "videoEnded", let messageBody = message.body as? String, messageBody == "ended" {
            DispatchQueue.main.async {
                self.switchActiveAndInactiveWebViews()
            }
        }
    }

    public func switchActiveAndInactiveWebViews() {
        (activeWebView, inactiveWebView) = (inactiveWebView, activeWebView)
        muteAndPause(webView: inactiveWebView)
    }
}

@available(iOS 13.0, *)
public struct WebViewWrapper: UIViewRepresentable {
    @ObservedObject var sdk: TrackPlayerSDK
    
    public func makeUIView(context: Context) -> UIView {
        // Create a container view to hold both web views
        let containerView = UIView()
        
        // Add the active web view
        let activeWebView = sdk.activeWebView
        containerView.addSubview(activeWebView)
        
        // Add constraints for the active web view
        activeWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activeWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activeWebView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            activeWebView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            activeWebView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Add the inactive web view
        let inactiveWebView = sdk.inactiveWebView
        containerView.addSubview(inactiveWebView)
        
        // Add constraints for the inactive web view
        inactiveWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            inactiveWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            inactiveWebView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            inactiveWebView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            inactiveWebView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Return the container view
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the UI view if needed
        // This method will be called whenever SwiftUI thinks the view needs to be updated
    }
}

