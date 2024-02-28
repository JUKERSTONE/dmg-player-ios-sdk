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
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        containerView.backgroundColor = .clear // Make the background clear
        containerView.layer.zPosition = -CGFloat.greatestFiniteMagnitude // Set to a very low z-index value
        
        // Assuming `sdk.primaryWebView` and `sdk.secondaryWebView` are already initialized and configured
        let primaryWebView = sdk.primaryWebView
        containerView.addSubview(primaryWebView)
        
        let secondaryWebView = sdk.secondaryWebView
        containerView.addSubview(secondaryWebView)
        
        // Since the container view is 1x1, the web views should also be constrained to match this size.
        [primaryWebView, secondaryWebView].forEach { webView in
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
                webView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
                webView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                webView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
        }
        
        // Other setup code, if necessary
        
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

