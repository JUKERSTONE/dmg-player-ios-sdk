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
        
        let bkPrimaryWebView = sdk.bkPrimaryWebView
        containerView.addSubview(bkPrimaryWebView)
        bkPrimaryWebView.translatesAutoresizingMaskIntoConstraints = false
        bkPrimaryWebView.isHidden = true
        containerView.addSubview(bkPrimaryWebView)
        
        let bkSecondaryWebView = sdk.bkSecondaryWebView
        containerView.addSubview(bkSecondaryWebView)
        bkSecondaryWebView.translatesAutoresizingMaskIntoConstraints = false
        bkSecondaryWebView.isHidden = true
        containerView.addSubview(bkSecondaryWebView)
        
        let primaryWebView = sdk.primaryWebView
        containerView.addSubview(primaryWebView)
        primaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            primaryWebView.topAnchor.constraint(equalTo: containerView.topAnchor),
            primaryWebView.widthAnchor.constraint(equalToConstant: 1),
            primaryWebView.heightAnchor.constraint(equalToConstant: 1),
            primaryWebView.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])

        let secondaryWebView = sdk.secondaryWebView
        containerView.addSubview(secondaryWebView)
        secondaryWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryWebView.topAnchor.constraint(equalTo: secondaryWebView.topAnchor),
            secondaryWebView.widthAnchor.constraint(equalToConstant: 1),
            secondaryWebView.heightAnchor.constraint(equalToConstant: 1),
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

