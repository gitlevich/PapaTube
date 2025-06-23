# Touch Map

## Screen regions
CO Controls overlay (buttons, scrub)
VS Video surface (behind overlays)
RG Recommendation Grid
SS Settings sheet

## Touch rules
1. Playing — controls visible  
   CO active  VS blocked

2. Playing — controls faded  
   CO active  VS blocked (tap wakes controls)

3. Scrubbing  
   CO (scrub) handles drag  VS blocked

4. Video ended — Grid shown  
   • Touch:  
      – RG active (tap tile chooses Video)  
      – CO active for Prev / Next buttons  
      – VS blocked  
   • Controls state: Play toggle shows "Play" (disabled), Prev/Next keep their enabled/disabled state.

5. Settings sheet open  
   SS active  CO, VS, RG blocked

## Pause-suggestion suppression
When the YouTube player surfaces its on-pause suggestion strip the system instantly covers it; region VS remains blocked and the strip is not visible. 
