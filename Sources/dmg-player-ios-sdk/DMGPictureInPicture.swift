// DMGPictureInPicture.swift

import SwiftUI
import WebKit

@available(iOS 13.0, *)
public struct DMGPictureLicense: UIViewRepresentable {
    @ObservedObject var sdk: DMGPlayerSDK
    
    public init(sdk: DMGPlayerSDK) {
            self.sdk = sdk
        }
    
    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        // Primary WebView setup
        let primaryWebView = sdk.primaryWebView
        containerView.addSubview(primaryWebView)
        
        primaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            primaryWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            primaryWebView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        primaryWebView.alpha = 0.1 // Make the primaryWebView invisible

        // Secondary WebView setup
        let secondaryWebView = sdk.secondaryWebView
        containerView.addSubview(secondaryWebView)
        
        secondaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            secondaryWebView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        secondaryWebView.alpha = 0.1 // Make the secondaryWebView invisible
        
        // Add other views here if necessary
        // Ensure that any other views are added after the web views
        // This will ensure that the web views stay at the back

        return containerView
    }

    
    public func updateUIView(_ uiView: UIView, context: Context) {
        let queuePublisher = sdk.$queue

        queuePublisher.sink { [weak sdk] updatedQueue in
            guard let sdk = sdk else { return }
            
            if sdk.index + 1 < updatedQueue.count {
                let nextUp = updatedQueue[sdk.index + 1]
                sdk.updatedPreload(isrc: nextUp)
            } else {
                print("No next item to preload")
            }
        }
    }


}

