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
            primaryWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            primaryWebView.widthAnchor.constraint(equalToConstant: 200), // Set width to 200 points
            primaryWebView.heightAnchor.constraint(equalToConstant: 80), // Maintain aspect ratio
            primaryWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor) // Center horizontally
        ])

        let secondaryWebView = sdk.secondaryWebView
        containerView.addSubview(secondaryWebView)

        secondaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryWebView.topAnchor.constraint(equalTo: secondaryWebView.bottomAnchor, constant: 8), // Add spacing between the web views
            secondaryWebView.widthAnchor.constraint(equalToConstant: 200),
            secondaryWebView.heightAnchor.constraint(equalTo: secondaryWebView.heightAnchor), // Match height with active web view
            secondaryWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor) // Center horizontally
        ])
        
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        let queuePublisher = sdk.$queue

        queuePublisher.sink { updatedQueue in
            if updatedQueue.count > 1 {
                let nextUp = updatedQueue[1]
                sdk.updatedPreload(isrc: nextUp)
            } else {
                let current = updatedQueue[0]
                sdk.playNow(isrc: current)
                print("Queue does not have a second element")
            }
        }
    }

}

