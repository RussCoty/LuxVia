//
//  ImageManager.swift
//  LuxVia
//
//  Created on 16/11/2025.
//

import Foundation
import UIKit

/// Manages slideshow images/videos for easy access across the app
class ImageManager {
    static let shared = ImageManager()
    
    private init() {}
    
    // MARK: - Convenience Access to Slideshows
    
    /// Get all available playlists
    func getAllPlaylists() -> [SlideshowPlaylist] {
        return SlideshowManager.shared.getAllPlaylists()
    }
    
    /// Get all media items across all playlists
    func getAllMediaItems() -> [SlideItem] {
        let playlists = SlideshowManager.shared.getAllPlaylists()
        return playlists.flatMap { $0.slides }
    }
    
    /// Create a new playlist
    func createPlaylist(name: String) -> SlideshowPlaylist {
        return SlideshowManager.shared.createPlaylist(name: name)
    }
    
    /// Add media to a playlist
    func addMediaToPlaylist(_ playlist: SlideshowPlaylist, slide: SlideItem) -> SlideshowPlaylist {
        var updated = playlist
        updated.slides.append(slide)
        SlideshowManager.shared.updatePlaylist(updated)
        return updated
    }
    
    /// Delete a playlist
    func deletePlaylist(_ playlist: SlideshowPlaylist) {
        SlideshowManager.shared.deletePlaylist(playlist)
    }
    
    /// Get media file URL
    func getMediaURL(for fileName: String) -> URL {
        return SlideshowManager.shared.getMediaURL(for: fileName)
    }
    
    /// Save media file
    func saveMediaFile(data: Data, fileName: String) -> URL? {
        return SlideshowManager.shared.saveMediaFile(data: data, fileName: fileName)
    }
    
    /// Delete media file
    func deleteMediaFile(fileName: String) {
        SlideshowManager.shared.deleteMediaFile(fileName: fileName)
    }
}
