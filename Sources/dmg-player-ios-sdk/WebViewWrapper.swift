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
                activeWebView.widthAnchor.constraint(equalToConstant: 300), // Set width to 300 points
                activeWebView.heightAnchor.constraint(equalToConstant: 80)
        ])

        // Add the inactive web view
        let inactiveWebView = sdk.inactiveWebView
        containerView.addSubview(inactiveWebView)

        // Add constraints for the inactive web view
        inactiveWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            inactiveWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            inactiveWebView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            inactiveWebView.widthAnchor.constraint(equalToConstant: 300), // Set width to 300 points
            inactiveWebView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Return the container view
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the UI view if needed
        // This method will be called whenever SwiftUI thinks the view needs to be updated
    }
}
