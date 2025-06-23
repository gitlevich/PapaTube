# Ubiquitous Language – Glossary

| Domain Concept | UI Projection (Name used in code/specs) | Notes |
|----------------|-----------------------------------------|-------|
| Playlist       | `playlistService.videos`                | Ordered collection of `Video` domain objects. |
| Video          | `Video` model struct                    | Holds title, id, YouTube URL. |
| Player         | **Player** view (embedded YouTube iframe) | Renders current video frame; no native controls shown (controls=0). |
| Controls Overlay | **Controls**                          | SwiftUI overlay containing UI projections below. Visible above Player. |
| Play / Pause command | **Play toggle** (`►` / `❚❚` button) | Reflects and mutates `isPlaying` flag in `AppModel`. |
| Next command   | **Next button** (`〉|`)                 | Advances `currentIndex` (+1). Disabled at end of playlist. |
| Previous command | **Prev button** (`|〈`)               | Decrements `currentIndex` (−1). Disabled at start of playlist. |
| Scrub capability | **Scrub bar** (Slider)                | Shows `currentTime` and allows seeking; fades with Controls. |
| Idle-fade rule | **Idle-fade**                           | 5-second timer reduces `Controls` opacity to 15 %. Reset on any user interaction. |
| Startup snapshot | **Startup snapshot**                  | First frame of last viewed video, shown paused on launch. |
| Recommendation strip | YouTube "More videos" bar        | Hidden by overlay + iframe params (`rel=0`). |

This glossary links domain language to concrete UI elements, ensuring developers, designers and stakeholders speak the same terms. 