# App 01 — AI Photo Editor

An AI-powered photo editing iOS app built with SwiftUI. Edit, enhance, and transform your photos using Apple's on-device AI.

## Screenshots (Simulator)

### Filter Results

| Original | Vivid | Mono | Fade | Chrome |
|:---:|:---:|:---:|:---:|:---:|
| <img src="photos/Screenshots/filter-original.png" width="150"/> | <img src="photos/Screenshots/filter-vivid.png" width="150"/> | <img src="photos/Screenshots/filter-mono.png" width="150"/> | <img src="photos/Screenshots/filter-fade.png" width="150"/> | <img src="photos/Screenshots/filter-chrome.png" width="150"/> |

### Auto Enhance

<table><tr>
  <td align="center"><b>Original</b><br/><img src="photos/Screenshots/monalisa-original.png" height="400"/></td>
  <td align="center"><b>Auto Enhanced</b><br/><img src="photos/Screenshots/monalisa-enhanced.png" height="400"/></td>
  <td align="center"><b>Reset</b><br/><img src="photos/Screenshots/monalisa-reset.png" height="400"/></td>
</tr></table>

## Features

- **AI Background Removal** — Remove backgrounds from portrait photos using Apple's Vision framework
- **AI Auto Enhance** — Automatically adjusts exposure, contrast, saturation and white balance
- **8 Photo Filters** — Original, Vivid, Mono, Fade, Chrome, Noir, Warm, Cool
- **Face Detection** — Detects and highlights faces in photos using Vision framework
- **Photo Import** — Import photos directly from your photo library
- **Export and Share** — Save edited photos or share to other apps
- **Works Offline** — All AI processing runs on-device

## Technologies

| Technology | Purpose |
|---|---|
| SwiftUI | UI framework |
| Vision | AI person segmentation, background removal, face detection |
| Core Image | Photo filters and auto enhancement |
| PhotosUI | Photo library access |

## Requirements

- iOS 17.4+
- Xcode 16+
- iPhone with Neural Engine (iPhone XS or later) for background removal

> **Simulator:** Filters and auto enhance work fully. Face detection requires a close-up portrait photo where the face fills at least ~25% of the frame — group shots and distant faces will not be detected. Background removal requires a real device (Neural Engine).

## Getting Started

1. Clone the repository
```bash
git clone https://github.com/preeti-chauhan/app-01-ai-photo-editor.git
```
2. Open `AIPhotoEditor.xcodeproj` in Xcode
3. Select your target device
4. Press `Cmd + R` to build and run

## License

MIT License
