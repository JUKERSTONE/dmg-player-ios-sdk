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
        let containerView = UIView()
        
        let activeWebView = sdk.activeWebView
        containerView.addSubview(activeWebView)
        
        activeWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activeWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activeWebView.widthAnchor.constraint(equalToConstant: 200), // Set width to 200 points
            activeWebView.heightAnchor.constraint(equalToConstant: 80), // Maintain aspect ratio
            activeWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor) // Center horizontally
        ])

        let inactiveWebView = sdk.inactiveWebView
        containerView.addSubview(inactiveWebView)

        inactiveWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            inactiveWebView.topAnchor.constraint(equalTo: activeWebView.bottomAnchor, constant: 8), // Add spacing between the web views
            inactiveWebView.widthAnchor.constraint(equalToConstant: 200),
            inactiveWebView.heightAnchor.constraint(equalTo: activeWebView.heightAnchor), // Match height with active web view
            inactiveWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor) // Center horizontally
        ])
        
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Observe changes to the queue property
        let queuePublisher = sdk.$queue
        
        // Sink to receive updates
        queuePublisher.sink { updatedQueue in
            // Check if the queue has been updated
            if sdk.index < updatedQueue.count {
                let isrc = updatedQueue[sdk.index]
                sdk.preloadNextVideo(isrc: isrc)
            } else {
                print("Index out of range")
            }
        }
    }
}
