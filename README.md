# Face Tracker <!-- omit from toc -->

Capture your expressions on any character of your choosing

## Table of Contents <!-- omit from toc -->

- [Description](#description)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Usage](#usage)
  - [Rational](#rational)
  - [Remarks](#remarks)
- [Disclaimer](#disclaimer)
- [Pull Requests](#pull-requests)
- [Credits](#credits)

## Description

This adds a Face Tracker tool, which contains a client websocket to the included Face Tracker websocket Python server.

### Features

[![Watch it work here](https://img.youtube.com/vi/Fg26dFWBvrI/0.jpg)](https://www.youtube.com/watch?v=Fg26dFWBvrI)

- Face pose capture
- Expression parsing with [MathParser](https://github.com/bytexenon/MathParser.lua/tree/v1.0.3) to map ARKit Blendshape values into facial flex values
- Preset saving and loading system to load settings across models with flex standards, such as FACS, ARKit, or HWM. 

### Requirements

- The client version nof [GWSockets by FredyH](https://github.com/FredyH/GWSockets) must be installed into your system. Look in the repository to understand how this all works
- Download the MediaPipe face landmarker model and place it somewhere next to the server folder (preferably in the server folder).
  - The `MODEL_PATH` variable in `server/gmod_facetracker.py` may need to be modified to accomodate for this location.

### Usage
1. If this is a fresh install, `pip install requirements.txt`
2. Ensure a webcam is plugged into your system, and start the server. You should see a window of a black screen with the landmarked face. If this window freezes, don't worry, as it will run once the client websocket connects
   - If you want to see your face in the window, find `image[:] = 0` in the `gmod_facetracker.py` code and comment that out: `#image[:] = 0`
3. Go into a GMod map in Sandbox mode and in singleplayer, find Face Tracker tool under Pose tab, and click `Connect`
4. If successful, the window with the landmarked face will move around and track your face.
5. Load in a preset and play around... or make your own!

### Rational

As far as I am aware, there only two cases of face motion capture in GMod: [FlexPoser](https://steamcommunity.com/sharedfiles/filedetails/?id=282498239) and [GPoser](https://github.com/swampservers/gposer). The former addon, however, is limited by the type of expressions one can make, and the motion capture only applies to a playermodel. While GPoser uses MediaPipe, this, too, is only limited to the playermodel.

This addon addresses these two limitations with a customizable system for mapping ARKit blendshapes into facial flexes, and can extend to any entity. These ARKit blendshapes are obtained from the current state-of-the-art of face pose estimation, thanks to MediaPipe's Face Landmarker solution. 

### Remarks

Naturally, as face pose capture implies acting performance capture abilities, this tool can be used to bake a facial performance into any GMod animation tool, particularly with Stop Motion Helper's Physics Recorder.

There are only a limited number of usable blendshapes out of the 52 ARKit blendshapes. `tongueOut`, and the `noseSneer` (left and right) blendshapes are currently zeroed out (from my experience).

This tool is limited to facial performance only. There are no plans to integrate MediaPipe's pose estimation solution (like in GPoser). 

## Disclaimer

**This tool has been tested in singleplayer.** Although this tool may function in multiplayer, please expect bugs and report any that you observe in the issue tracker.

## Pull Requests

When making a pull request, make sure to confine to the style seen throughout. Try to add types for new functions or data structures. I used the default [StyLua](https://github.com/JohnnyMorganz/StyLua) formatting style.

## Credits

- [GWSockets by FredyH](https://github.com/FredyH/GWSockets)
- [MathParser by bytexenon](https://github.com/bytexenon/MathParser.lua/tree/v1.0.3)
- Google for MediaPipe Face Landmarker solution