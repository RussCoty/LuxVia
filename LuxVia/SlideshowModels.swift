//
//  SlideshowModels.swift
//  LuxVia
//
//  Created on 16/11/2025.
//

import Foundation
import UIKit

/// Represents a single slide item (image or video)
struct SlideItem: Codable, Equatable {
    let id: UUID
    let fileName: String
    let type: SlideType
    let duration: TimeInterval // How long to display (for images) or video length
    let order: Int
    
    enum SlideType: String, Codable {
        case image
        case video
    }
    
    init(id: UUID = UUID(), fileName: String, type: SlideType, duration: TimeInterval = 5.0, order: Int = 0) {
        self.id = id
        self.fileName = fileName
        self.type = type
        self.duration = duration
        self.order = order
    }
}

/// Represents a slideshow playlist with display settings
struct SlideshowPlaylist: Codable, Equatable {
    let id: UUID
    var name: String
    var slides: [SlideItem]
    var settings: SlideshowSettings
    
    init(id: UUID = UUID(), name: String, slides: [SlideItem] = [], settings: SlideshowSettings = SlideshowSettings()) {
        self.id = id
        self.name = name
        self.slides = slides
        self.settings = settings
    }
}

/// Settings for how the slideshow should be displayed
struct SlideshowSettings: Codable, Equatable {
    var loopEnabled: Bool
    var transitionStyle: TransitionStyle
    var defaultImageDuration: TimeInterval // Default duration for images
    var shuffleEnabled: Bool
    
    enum TransitionStyle: String, Codable {
        case fade
        case dissolve
        case slideLeft
        case slideRight
        case none
    }
    
    init(loopEnabled: Bool = true,
         transitionStyle: TransitionStyle = .fade,
         defaultImageDuration: TimeInterval = 5.0,
         shuffleEnabled: Bool = false) {
        self.loopEnabled = loopEnabled
        self.transitionStyle = transitionStyle
        self.defaultImageDuration = defaultImageDuration
        self.shuffleEnabled = shuffleEnabled
    }
}
