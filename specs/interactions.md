# Interaction Reference Spec

## Domain Terms

* **Video** – a single YouTube video entity that can be played.
* **Playlist** – ordered collection of Videos provided by a YouTube playlist ID.
* **Controls** – on-screen playback UI (Play/Pause toggle, Prev, Next, Scrub bar, gear icon).
* **Play toggle** – button that alternates between "Play" and "Pause" icons/states.
* **Prev button** – skips to the previous Video; disabled at the first Video.
* **Next button** – skips to the next Video; disabled at the last Video.
* **Scrub bar** – slider that shows progress and allows seeking within the current Video.
* **Idle-fade** – automatic opacity reduction of Controls after inactivity.
* **Recommendation Grid** – 2×N grid of Video thumbnails shown after a Video ends.
* **Settings sheet** – modal view where the viewer can sign in/out and change the Playlist ID.
* **Viewer** – the end-user operating the app.

---

## Interaction Catalogue

1. **Play**  
   *Given* Controls are visible, the Video is paused, and the Play toggle shows "Play".  
   *When* the viewer presses the Play toggle.  
   *Then* the Video plays and the Play toggle changes to "Pause".

2. **Pause**  
   *Given* the Video is playing and the Play toggle shows "Pause".  
   *When* the viewer presses the Play toggle.  
   *Then* the Video pauses and the Play toggle changes to "Play".

3. **Next**  
   *Given* the Playlist has a next Video and the Next button is enabled.  
   *When* the viewer presses the Next button.  
   *Then* the next Video begins playing; Prev becomes enabled and Next may disable if now at the last Video.

4. **Previous**  
   *Given* the Playlist has a previous Video and the Prev button is enabled.  
   *When* the viewer presses the Prev button.  
   *Then* the previous Video begins playing; Next becomes enabled and Prev may disable if now at the first Video.

5. **Scrub (seek)**  
   *Given* Controls are visible and the Scrub bar shows current progress.  
   *When* the viewer drags the Scrub bar and releases at time **T**.  
   *Then* playback resumes from **T** and the Scrub bar thumb snaps to **T**.

6. **Idle-fade**  
   *Given* Controls are fully visible (100 % opacity) while a Video is playing.  
   *When* 5 seconds pass with no viewer interaction.  
   *Then* Controls fade to 15 % opacity.

7. **Wake Controls**  
   *Given* Controls are faded (15 % opacity).  
   *When* the viewer taps the screen or interacts with any control.  
   *Then* Controls return to 100 % opacity and the idle-fade timer restarts.

8. **Startup resume**  
   *Given* the app launches and a saved resume point exists for the first Video.  
   *When* the initial frame appears.  
   *Then* that Video is paused at the saved time; Play toggle shows "Play"; Scrub bar reflects the saved position.

9. **Video completion → Recommendation Grid**  
   *Given* a Video is playing and Controls are visible.  
   *When* the Video ends.  
   *Then* the Recommendation Grid appears and Controls disappear.

10. **Select video from Recommendation Grid**  
    *Given* the Recommendation Grid is displayed and Controls are hidden.  
    *When* the viewer taps a Video tile.  
    *Then* the Grid disappears, the chosen Video starts playing, and Controls appear showing the Play toggle as "Pause".

11. **Open Settings**  
    *Given* Controls are visible.  
    *When* the viewer presses the gear icon.  
    *Then* the Settings sheet opens and overlay controls behind it become inactive.

12. **Change Playlist**  
    *Given* the Settings sheet is open.  
    *When* the viewer enters a new playlist URL/ID and confirms.  
    *Then* the new Playlist loads; playback is positioned at the first Video (paused at 0 s); Prev is disabled and Next is enabled.

13. **Google sign-in**  
    *Given* the viewer is not authenticated and the "Authenticate with Google" button is shown.  
    *When* the button is pressed and sign-in succeeds.  
    *Then* private playlists can be loaded and the button label changes to "Sign out of Google".

14. **Google sign-out**  
    *Given* the viewer is authenticated and the "Sign out of Google" button is shown.  
    *When* the button is pressed.  
    *Then* the viewer is signed out, private playlists become unavailable, and the button label changes back to "Authenticate with Google". 