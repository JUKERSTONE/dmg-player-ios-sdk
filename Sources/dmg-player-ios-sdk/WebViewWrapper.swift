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
        
        // Add the inactive web view
        let inactiveWebView = sdk.inactiveWebView
        containerView.addSubview(inactiveWebView)
        
        // Return the container view
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the UI view if needed
        // This method will be called whenever SwiftUI thinks the view needs to be updated
    }
}
