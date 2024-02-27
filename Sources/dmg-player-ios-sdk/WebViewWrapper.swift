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
            activeWebView.widthAnchor.constraint(equalToConstant: 200), // Set width to 200 points
            activeWebView.heightAnchor.constraint(equalTo: activeWebView.widthAnchor, multiplier: 9.0/16.0), // Maintain aspect ratio
            activeWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor) // Center horizontally
        ])

        // Add the inactive web view
        let inactiveWebView = sdk.inactiveWebView
        containerView.addSubview(inactiveWebView)

        // Add constraints for the inactive web view
        inactiveWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            inactiveWebView.topAnchor.constraint(equalTo: activeWebView.bottomAnchor, constant: 8), // Add spacing between the web views
            inactiveWebView.widthAnchor.constraint(equalToConstant: 200),
            inactiveWebView.heightAnchor.constraint(equalTo: activeWebView.heightAnchor), // Match height with active web view
            inactiveWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor) // Center horizontally
        ])
        
        // Return the container view
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the UI view if needed
        // This method will be called whenever SwiftUI thinks the view needs to be updated
    }
}
