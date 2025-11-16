# AirPlay Slideshow Feature - User Guide

## Overview
The LuxVia app now includes a powerful AirPlay slideshow feature that allows you to display images and videos on an external display (via AirPlay or HDMI) while continuing to use the app on your device.

## Features

### ✨ Core Functionality
- **Upload Media**: Add images and videos from your photo library
- **Playlist Management**: Create and manage multiple slideshow playlists
- **Loop Mode**: Continuously loop through slides or play once
- **Shuffle Mode**: Randomize slide order
- **Individual Display**: Show specific slides manually or let them auto-advance
- **AirPlay Support**: Display slideshow on external screens while using the app
- **Video Support**: Play video files with automatic progression
- **Customizable Duration**: Set how long each image displays (1-30 seconds)
- **Transition Effects**: Choose from Fade, Dissolve, Slide Left, Slide Right, or None

### 🎬 Slideshow Controls
- **Play/Pause**: Start or pause the slideshow
- **Stop**: End the slideshow and return to ready state
- **Previous**: Go back to the previous slide
- **Next**: Skip to the next slide

## How to Use

### 1. Accessing the Slideshow Tab
1. Open the LuxVia app
2. Tap the **Slideshow** tab at the bottom of the screen (fourth tab)
3. You'll see the slideshow interface with controls and media list

### 2. Adding Media to Your Slideshow

#### Add Images
1. Tap the **Add Media** button at the top
2. Select **Add Images**
3. Choose one or more images from your photo library
4. Images will appear in your slideshow playlist

#### Add Videos
1. Tap the **Add Media** button
2. Select **Add Videos**
3. Choose one or more videos from your photo library
4. Videos will appear in your slideshow playlist with their duration

### 3. Managing Playlists

#### Create a New Playlist
1. Tap the **New Playlist** button
2. Enter a name for your playlist
3. Tap **Create**
4. Your new empty playlist is now active

#### Reorder Slides
1. Tap and hold on a slide in the list
2. Drag it to the desired position
3. Release to drop it in place

#### Delete Slides
1. Swipe left on a slide in the list
2. Tap **Delete**
3. The slide will be removed from the playlist

### 4. Configuring Slideshow Settings
1. Tap the **Settings** button (gear icon)
2. Adjust the following settings:
   - **Loop Slideshow**: Enable to continuously loop through slides
   - **Shuffle**: Enable to randomize the slide order
   - **Default Duration**: Set how long images display (1-30 seconds)
   - **Transition Effect**: Choose your preferred transition style

3. Tap **Save** to apply changes

### 5. Starting the Slideshow

#### Connect to AirPlay
1. Ensure your AirPlay device (Apple TV, AirPlay-enabled TV, or projector) is on the same network
2. Swipe down from the top-right corner (or up from the bottom on older devices) to open Control Center
3. Tap **Screen Mirroring**
4. Select your AirPlay device

#### Start Playback
1. Ensure you have added slides to your playlist
2. Tap the **Play** button (▶️)
3. The slideshow will begin displaying on the external screen
4. You can continue using the app on your device

#### Control During Playback
- **Pause**: Tap the Play button (now shows ⏸)
- **Stop**: Tap the Stop button (⏹)
- **Navigate**: Use Previous (⏮) and Next (⏭) buttons
- The status label shows the current slide and position

### 6. Display Modes

#### Auto-Advance Mode (Default)
- Images automatically advance after the set duration
- Videos play to completion, then advance to the next slide
- Perfect for unattended displays

#### Manual Control Mode
- Pause the slideshow
- Use Previous/Next buttons to manually control slides
- Great for presentations where you control the timing

## Technical Details

### Supported File Formats
- **Images**: JPEG, PNG, HEIC, and most common image formats
- **Videos**: MP4, MOV, and formats supported by iOS AVFoundation

### Storage
- All slideshow media is stored locally on your device
- Files are saved in the app's documents directory
- Playlists and settings are persisted between app launches

### Background Operation
- The slideshow runs on a separate window from the main app
- You can use other features of LuxVia while the slideshow plays
- Slideshow continues even when switching tabs

### Performance Tips
- Large video files may take time to load
- Recommended maximum video length: 5 minutes per clip
- For best performance, use compressed images (under 5MB each)
- Limit playlists to 50-100 items for smooth operation

## Troubleshooting

### Slideshow Not Appearing on External Display
1. Check AirPlay connection in Control Center
2. Ensure external display is set as the active screen
3. Try disconnecting and reconnecting AirPlay
4. Restart the slideshow

### Videos Not Playing
1. Check video format compatibility
2. Ensure videos aren't corrupted
3. Try re-importing the video
4. Check that video isn't DRM-protected

### Images Not Loading
1. Grant photo library access in Settings > Privacy > Photos
2. Re-import images if thumbnails don't appear
3. Check available storage space

### App Performance Issues
1. Reduce number of slides in playlist
2. Compress large images before importing
3. Close and restart the app
4. Clear old playlists you no longer use

## Use Cases

### Funeral Services
- Display photo memories during the service
- Show a tribute video
- Create a peaceful background slideshow

### Memorial Events
- Loop through family photos
- Display messages and quotes
- Combine images and video tributes

### Wake or Reception
- Create an ambient photo display
- Show a chronological life story
- Display multiple slideshows throughout the event

## Tips and Best Practices

1. **Prepare in Advance**: Create and test your slideshow before the event
2. **Use Loop Mode**: Enable looping for background displays
3. **Set Appropriate Duration**: 5-10 seconds per image is usually ideal
4. **Mix Media**: Combine photos and short video clips for variety
5. **Test AirPlay**: Verify connection with your display equipment beforehand
6. **Organize Playlists**: Create separate playlists for different parts of the service
7. **Check Orientation**: Ensure images are properly oriented before importing

## Files Created

The slideshow feature adds the following new files to your project:

1. **SlideshowModels.swift** - Data models for slides, playlists, and settings
2. **SlideshowManager.swift** - Core slideshow playback and management logic
3. **SlideshowViewController.swift** - Main UI for managing slideshows
4. **AirPlaySlideshowViewController.swift** - External display view controller
5. **SlideshowSettingsViewController.swift** - Settings configuration UI

All files follow the existing LuxVia code architecture and naming conventions.
