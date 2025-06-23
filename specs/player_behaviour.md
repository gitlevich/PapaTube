# Player Behaviour Specification

## Entities
- **Player** – Embedded YouTube surface that renders video frames.
- **Controls** – Custom overlay that includes Play toggle, Next, Prev and Scrub bar.
- **Play toggle** – Round button showing ► when stopped and ❚❚ when playing.
- **Idle-fade** – Automatic reduction of Controls' opacity to 15 % after 5 s of inactivity.
- **Startup snapshot** – First frame of the last-viewed video shown on app launch.

## Rules

### 1. Launch
| ID | Description |
|----|-------------|
| R-1.1 | Player displays Startup snapshot. |
| R-1.2 | Playback is paused. |
| R-1.3 | Play toggle shows ►. |

### 2. Play / Pause
| ID | Description |
|----|-------------|
| R-2.1 | Pressing Play toggle while paused starts playback and switches icon to ❚❚. |
| R-2.2 | Pressing it again pauses playback and switches icon back to ►. |

### 3. Navigation (Next / Prev)
| ID | Description |
|----|-------------|
| R-3.1 | If playing, Next/Prev loads target video and auto-plays it. |
| R-3.2 | If paused, Next/Prev loads target video but leaves it paused. |
| R-3.3 | Prev is disabled on first video; Next is disabled on last video. |

### 4. Controls Visibility
| ID | Description |
|----|-------------|
| R-4.1 | Idle-fade triggers 5 s after last interaction. |
| R-4.2 | Any interaction aborts fade and restores full opacity. |
| R-4.3 | Idle-fade affects only buttons; Scrub bar remains full-opacity. |

### 5. "More videos" Bar
| ID | Description |
|----|-------------|
| R-5.1 | Native YouTube recommendation strip is never visible (covered + iFrame params). |

### 6. Serial Loading
| ID | Description |
|----|-------------|
| R-6.1 | Only one asynchronous `load` may run; new loads cancel previous ones. |

### 7. State Persistence
| ID | Description |
|----|-------------|
| R-7.1 | Current index and play/pause state are stored on background and restored on launch. |

## Behaviour Scenarios

### Launch
```
Given the app was last closed on Video #n
When the user opens the app
Then Player shows Video #n at 0 s, paused, Play toggle = ►
```

### Normal viewing
```
Given Player is playing and Controls are dimmed
When the user taps Next
Then Controls brighten, Idle-fade restarts, next video auto-plays
```

### Paused navigation
```
Given Player is paused on Video #n
When the user taps Next
Then Video #(n+1) loads, remains paused, Play toggle = ►
```

### Idle-fade
```
Given no interaction for 5 s
Then Controls fade to 15 % opacity
When the user interacts
Then Controls return to 100 % and timer restarts
``` 