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
        
        let freeloadingBuffer = sdk.freeloadingBuffer
        containerView.addSubview(freeloadingBuffer)
        freeloadingBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            freeloadingBuffer.topAnchor.constraint(equalTo: containerView.topAnchor),
            freeloadingBuffer.widthAnchor.constraint(equalToConstant: 1),
            freeloadingBuffer.heightAnchor.constraint(equalToConstant: 1),
            freeloadingBuffer.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        let backgroundPrimaryBuffer = sdk.backgroundPrimaryBuffer
        containerView.addSubview(backgroundPrimaryBuffer)
        backgroundPrimaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundPrimaryBuffer.topAnchor.constraint(equalTo: containerView.topAnchor),
            backgroundPrimaryBuffer.widthAnchor.constraint(equalToConstant: 1),
            backgroundPrimaryBuffer.heightAnchor.constraint(equalToConstant: 1),
            backgroundPrimaryBuffer.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        let foregroundPrimaryBuffer = sdk.foregroundPrimaryBuffer
        containerView.addSubview(foregroundPrimaryBuffer)
        foregroundPrimaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            foregroundPrimaryBuffer.topAnchor.constraint(equalTo: containerView.topAnchor),
            foregroundPrimaryBuffer.widthAnchor.constraint(equalToConstant: 1),
            foregroundPrimaryBuffer.heightAnchor.constraint(equalToConstant: 1),
            foregroundPrimaryBuffer.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])

        let foregroundSecondaryBuffer = sdk.foregroundSecondaryBuffer
        containerView.addSubview(foregroundSecondaryBuffer)
        foregroundSecondaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            foregroundSecondaryBuffer.topAnchor.constraint(equalTo: foregroundSecondaryBuffer.topAnchor),
            foregroundSecondaryBuffer.widthAnchor.constraint(equalToConstant: 1),
            foregroundSecondaryBuffer.heightAnchor.constraint(equalToConstant: 1),
            foregroundSecondaryBuffer.centerXAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        let queuePublisher = sdk.$queue

        queuePublisher.sink { [weak sdk] updatedQueue in
            guard let sdk = sdk else { return }
            
            if sdk.index + 1 < updatedQueue.count {
                sdk.updatedPreload(buffer: updatedQueue, index : sdk.index)
            } else {
                print("No next item to preload")
            }
        }
    }
}

