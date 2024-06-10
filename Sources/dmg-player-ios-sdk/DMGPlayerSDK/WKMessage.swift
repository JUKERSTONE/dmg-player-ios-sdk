/**
 WKMessage.swift
 © 2024 Jukerstone. All rights reserved.
 */

import Foundation
import WebKit

@available(iOS 13.0, *)
extension DMGPlayerSDK {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "player" {
            guard let messageString = message.body as? String else {
                print("The message body is not a string.")
                return
            }

            guard let jsonData = messageString.data(using: .utf8) else {
                print("Could not convert message string to Data.")
                return
            }

            guard let messageDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                print("Failed to deserialize JSON string into a dictionary.")
                return
            }

            guard let eventType = messageDict["eventType"] as? String else {
                print("The 'eventType' is not a string or not present in the message body.")
                return
            }

            switch eventType {
            case "videoProgress":
                return
            case "enablePiP":
                if let data = messageDict["data"] as? Double {
                    print(data, "Pip Data")
                } else {
                    print("Error PiP")
                }
            case "videoEnded":
                if self.isFreeRunning {
                    return
                }
                
                if self.isPrimaryActive {
                    self.isPrimaryActive = false
                    self.play(webView: self.foregroundSecondaryBuffer)
                } else {
                    self.isPrimaryActive = true
                    self.play(webView: self.foregroundPrimaryBuffer)
                }
            default:
                print("Unknown event type received: \(eventType)")
            }
        } else {
            print("Received a message from an unexpected handler: \(message.name)")
        }
    }
    
}
