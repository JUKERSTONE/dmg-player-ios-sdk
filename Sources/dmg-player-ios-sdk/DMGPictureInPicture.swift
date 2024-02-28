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
        
        let primaryWebView = sdk.primaryWebView
        containerView.addSubview(primaryWebView)
        
        primaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            primaryWebView.topAnchor.constraint(equalTo: 0),
            primaryWebView.widthAnchor.constraint(equalToConstant: 1), // Set width to 200 points
            primaryWebView.heightAnchor.constraint(equalToConstant: 1), // Maintain aspect ratio
            primaryWebView.centerXAnchor.constraint(equalTo: 0) // Center horizontally
        ])

        let secondaryWebView = sdk.secondaryWebView
        containerView.addSubview(secondaryWebView)

        secondaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryWebView.topAnchor.constraint(equalTo: 0), // Add spacing between the web views
            secondaryWebView.widthAnchor.constraint(equalToConstant: 1),
            secondaryWebView.heightAnchor.constraint(equalToConstant: 1), // Matåch height with active web view
            secondaryWebView.centerXAnchor.constraint(equalTo: 0) // Center horizontally
        ])
        
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

