# PapaTube – Consolidated Specification

This document unifies all agreed-upon requirements using the project's
ubiquitous language.  It supersedes earlier fragments in `player_behaviour.md`
but references the same rule numbers for traceability.

## Glossary (Domain ↔︎ UI)
| Domain Concept | UI Projection | Notes |
|----------------|--------------|-------|
| Playlist | `playlistService.videos` | Ordered collection of `Video` items. |
| Video | `Video` struct | Contains title, id, URL. |
| Player | YouTube iFrame (no native controls) | Renders the current Video. |
| Controls overlay | **Controls** | SwiftUI layer above Player. |
| Play toggle | **Play toggle** | Round button (► / ❚❚). |
| Next / Prev command | **Next** / **Prev** buttons | Navigate playlist. |
| Scrub capability | **Scrub bar** | Slider showing & seeking current time. |
| Idle-fade | Auto-dim | After 5 s opacity → 15 %. |
| Startup snapshot | Startup frame | First frame of last viewed Video. |
| Recommendation strip / grid | YouTube suggestions | Appears when Player ends. Covered unless state == *ended*. |

## Rules
### R-1  Launch
1.1  Player shows Startup snapshot.  
1.2  Playback is paused.  
1.3  Play toggle shows ►.

### R-2  Play / Pause
2.1  Pressing Play toggle while paused starts playback (icon → ❚❚).  
2.2  Pressing again pauses playback (icon → ►).  
2.3  During the **play handshake** the Cover overlay hides the suggestion strip for 0.7 s.

### R-3  Navigation
3.1  If `isPlaying == true` Next/Prev auto-play the target Video.  
3.2  If paused, Next/Prev load target Video but stay paused.  
3.3  Prev disabled at index 0; Next disabled at last index.

### R-4  Controls visibility
4.1  Idle-fade triggers 5 s after last interaction.  
4.2  Any interaction cancels fade and restores full opacity.  
4.3  Idle-fade dims entire Controls overlay (buttons + Scrub bar).

### R-5  Recommendation grid
5.1  Player covers the YouTube suggestion strip in all states except *ended*.  
5.2  When **Ended flag** is true:  
 • Cover overlay removed.  
 • Controls overlay hidden.  
 • Hit-blocking layers disabled.  
 → Full-screen grid is bright and fully interactive.  
5.3  Selecting a tile (or Prev) resets **Ended flag** and normal behaviour resumes.

### R-6  Serial loading
Only one async `player.load` may run. A new load cancels the previous task.

### R-7  State persistence
`currentIndex`, `isPlaying`, and cached positions are saved on background and restored on launch.

## Behaviour Scenarios
(see `player_behaviour.md` for detailed Gherkin-style scripts; they remain valid). 