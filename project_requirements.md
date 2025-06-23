# Project Requirements

## Overview

An iOS app for users with severe limb/speech aphasia and apraxia, to help them watch YouTube videos. The native YouTube app is too complex for them to use, and they need an app with drastically simplified controls.

The app will use a single playlist retrieved from a GitHub repository, containing a list of videos admin picked for the user. The playlist will be updated by the admin, and the app will automatically update to the latest version. It expose a single small Sync button out of the way, to allow the admin to manually sync the playlist.

## App behavior

### Primary User (Papa)

  A person with limb apraxia and aphasia who needs simple, accessible video playback

  Core Playback Stories

  As Papa, I want to:

  1. Play/Pause Videos
    - Tap anywhere on the video to play or pause
    - See large, clear visual feedback when pausing
    - Resume exactly where I left off when I return to a video
  2. Navigate Between Videos
    - Use large, simple navigation buttons to go to next/previous video
    - Have buttons that are easy to see and tap (60pt size)
    - Continue watching videos automatically without having to choose
  3. Resume Where I Left Off
    - Return to the exact position I was watching when I switch videos
    - Have the app remember my position even if I close the app
    - Never lose my place in long videos
  4. Simple Interface
    - See only essential controls (no complex YouTube interface)
    - Have a clean, uncluttered screen focused on the video
    - Use the app in landscape mode for comfortable viewing
  5. Reliable Playback
    - Have videos start playing automatically when selected
    - Never get stuck on loading screens or spinners
    - Experience smooth video playback without interruptions


### Admin user

As an admin, I want to:

1. sync the playlist with the latest version in the GitHub repository
2. ensure that my YouTube api key is not exposed to the public when the app is pushed to GitHub (proper secret management)