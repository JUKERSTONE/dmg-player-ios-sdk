//
//  File.swift
//  
//
//  Created by TSB M3DIA on 28/02/2024.
//

import Foundation

public func buildActiveJavaScript() -> String {
    // JavaScript code to unmute and play the video
    return """
    // Unmute and play the video
    window.trakStarVideo.muted = false;
    window.trakStarVideo.play();
    window.trakStarVideo.requestPictureInPicture().then(() => {
        const message = {
            eventType: 'enablePiP',
            data: 'PiP initiated successfully.'
        };
        window.webkit.messageHandlers.player.postMessage(JSON.stringify(message));
    }).catch(error => {
        const message = {
            eventType: 'enablePiP',
            data: 'PiP initiation failed: ' + error.message
        };
        window.webkit.messageHandlers.player.postMessage(JSON.stringify(message));
    });
    """
}

public func buildInactiveJavaScript() -> String {
    // JavaScript code to mute and pause the video
    return """
    // Mute and pause the video
    window.trakStarVideo.muted = true;
    window.trakStarVideo.pause();
    """
}
