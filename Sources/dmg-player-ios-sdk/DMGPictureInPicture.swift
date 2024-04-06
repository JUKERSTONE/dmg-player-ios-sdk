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
        let foregroundPrimaryBuffer = sdk.foregroundPrimaryBuffer
        sdk.containerView.addSubview(foregroundPrimaryBuffer)
        foregroundPrimaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            foregroundPrimaryBuffer.topAnchor.constraint(equalTo: sdk.containerView.topAnchor),
            foregroundPrimaryBuffer.widthAnchor.constraint(equalToConstant: 1),
            foregroundPrimaryBuffer.heightAnchor.constraint(equalToConstant: 1),
            foregroundPrimaryBuffer.centerXAnchor.constraint(equalTo: sdk.containerView.leadingAnchor)
       ])

        let foregroundSecondaryBuffer = sdk.foregroundSecondaryBuffer
        sdk.containerView.addSubview(foregroundSecondaryBuffer)
        foregroundSecondaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            foregroundSecondaryBuffer.topAnchor.constraint(equalTo: sdk.containerView.topAnchor),
            foregroundSecondaryBuffer.widthAnchor.constraint(equalToConstant: 1),
            foregroundSecondaryBuffer.heightAnchor.constraint(equalToConstant: 1),
            foregroundSecondaryBuffer.centerXAnchor.constraint(equalTo: sdk.containerView.leadingAnchor)
       ])
        
        let backgroundBuffer = sdk.backgroundBuffer
        sdk.containerView.addSubview(backgroundBuffer)
        backgroundBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundBuffer.topAnchor.constraint(equalTo: sdk.containerView.topAnchor),
            backgroundBuffer.widthAnchor.constraint(equalToConstant: 1),
            backgroundBuffer.heightAnchor.constraint(equalToConstant: 1),
            backgroundBuffer.centerXAnchor.constraint(equalTo: sdk.containerView.leadingAnchor)
       ])
        
        let backgroundRunningPrimaryBuffer = sdk.backgroundRunningPrimaryBuffer
        sdk.containerView.addSubview(backgroundRunningPrimaryBuffer)
        backgroundRunningPrimaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundRunningPrimaryBuffer.topAnchor.constraint(equalTo: sdk.containerView.topAnchor),
            backgroundRunningPrimaryBuffer.widthAnchor.constraint(equalToConstant: 1),
            backgroundRunningPrimaryBuffer.heightAnchor.constraint(equalToConstant: 1),
            backgroundRunningPrimaryBuffer.centerXAnchor.constraint(equalTo: sdk.containerView.leadingAnchor)
       ])
        
        let backgroundRunningSecondaryBuffer = sdk.backgroundRunningSecondaryBuffer
        sdk.containerView.addSubview(backgroundRunningSecondaryBuffer)
        backgroundRunningSecondaryBuffer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundRunningSecondaryBuffer.topAnchor.constraint(equalTo: sdk.containerView.topAnchor),
            backgroundRunningSecondaryBuffer.widthAnchor.constraint(equalToConstant: 1),
            backgroundRunningSecondaryBuffer.heightAnchor.constraint(equalToConstant: 1),
            backgroundRunningSecondaryBuffer.centerXAnchor.constraint(equalTo: sdk.containerView.leadingAnchor)
       ])
        
        return sdk.containerView
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

