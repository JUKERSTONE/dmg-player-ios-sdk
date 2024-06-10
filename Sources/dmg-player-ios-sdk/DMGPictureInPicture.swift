/**
 DMGPictureInPicture.swift
 © 2024 Jukerstone. All rights reserved.
 */

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
        
        let foregroundPrimaryBuffer = sdk.foregroundPrimaryBuffer
        containerView.addSubview(foregroundPrimaryBuffer)
        foregroundPrimaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            foregroundPrimaryBuffer.topAnchor.constraint(equalTo: containerView.topAnchor),
            foregroundPrimaryBuffer.widthAnchor.constraint(equalToConstant: 100),
            foregroundPrimaryBuffer.heightAnchor.constraint(equalToConstant: 200),
            foregroundPrimaryBuffer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
       ])

        let foregroundSecondaryBuffer = sdk.foregroundSecondaryBuffer
        containerView.addSubview(foregroundSecondaryBuffer)
        foregroundSecondaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            foregroundSecondaryBuffer.topAnchor.constraint(equalTo: containerView.topAnchor),
            foregroundSecondaryBuffer.widthAnchor.constraint(equalToConstant: 100),
            foregroundSecondaryBuffer.heightAnchor.constraint(equalToConstant: 200),
            foregroundSecondaryBuffer.centerXAnchor.constraint(equalTo: containerView.trailingAnchor)
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

