import UIKit
import SwiftUI
import WebKit

@available(iOS 13.0, *)
public struct WebViewWrapper: UIViewRepresentable {
    @ObservedObject var sdk: TrackPlayerSDK
    
    public init(sdk: TrackPlayerSDK) {
        self.sdk = sdk
    }
    
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
        
        // Set up message handlers for both active and inactive web views
        activeWebView.configuration.userContentController.add(context.coordinator, name: "activeWebViewEvent")
        inactiveWebView.configuration.userContentController.add(context.coordinator, name: "inactiveWebViewEvent")
        
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the UI view if needed
        // This method will be called whenever SwiftUI thinks the view needs to be updated
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: WebViewWrapper
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Handle messages received from both active and inactive web views
            if message.name == "activeWebViewEvent" {
                // Handle message received from the active web view
                let body = message.body as? String ?? ""
                print("Received message from active web view: \(body)")
                // Process the message and take appropriate actions
            } else if message.name == "inactiveWebViewEvent" {
                // Handle message received from the inactive web view
                let body = message.body as? String ?? ""
                print("Received message from inactive web view: \(body)")
                // Process the message and take appropriate actions
            }
        }
    }
}
