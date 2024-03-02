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
            primaryWebView.widthAnchor.constraint(equalToConstant: 200),
            primaryWebView.heightAnchor.constraint(equalToConstant: 200),
            primaryWebView.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])

        let secondaryWebView = sdk.secondaryWebView
        containerView.addSubview(secondaryWebView)

        secondaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryWebView.topAnchor.constraint(equalTo: secondaryWebView.topAnchor),
            secondaryWebView.widthAnchor.constraint(equalToConstant: 200),
            secondaryWebView.heightAnchor.constraint(equalToConstant: 200),
            secondaryWebView.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
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

