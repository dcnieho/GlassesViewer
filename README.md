# About
This matlab utility can parse recording files from the Tobii Glasses 2
as stored on the SD card (no need for intervening Tobii software). Once
parsed, it will display this data in a matlab GUI. Optional eye videos
are also supported.

NB: do not expect fluent playback. I get a few frames a second on my 4K
display, the matlab GUI renderer can't handle all this.

Tested on Matlab R2017b. Because a bunch of java hacks are used for the
GUI, it is quite possible that the viewer part of this repository is not
all that compatible with different matlab versions. Pull requests
welcomed!

# Screenshot
![Glasses viewer screenshot](/screenshot.jpg?raw=true)

# Usage
When running the viewer GUI, `glassesViewer.m`, a file picker will
appear. Select the folder of a recording to view. This needs to point to
a specific recording's folder. If "projects" is the project folder on
the SD card, an example of a specific recording is:
    `projects\rkamrkb\recordings\zi4xmt2`

If you just wish to parse the Tobii glasses data into a MATLAB readable
file, you can directly call
`./function_library/TobiiGlassesRecordings/getTobiiDataFromGlasses.m`
with the same specific recording as above as the input argument.

Default settings for the reader are in the `default.json` file. To alter
these settings, read in the json file with `jsondecode()`, change any
values in the resulting struct, and pass that as an input argument to
`glassesViewer`.

# Viewer interface
keys:
- left arrow or `a` key: show previous data window
- right arrow or `d` key: show next data window
- `space bar`: start/stop playback
- `z`: enter/exit zoom mode
- `ctrl`+`r`: reset vertical axes limits

mouse:
- can drag the time indicator (red line in data axes) with left mouse
  button. `escape` key cancels this action.
- dragging with right mouse button (or left mouse button + `cnrl`) moves
  the visible data in the window
- double-click on data axis sets time to clicked time
- using mouse scrollwheel when on data axis has two functions:
1. if holding down `ctrl`, the time window is zoomed along the cursor
position
2. if holding down `shift`, the value range of the vertical axis is
zoomed along the cursor position

# TODOs
- progress bar when loading in data Tobii data (not linear time but can indicate steps completed or so)
- support for viewing data from other systems (e.g. SMI glasses)
- make fancier file picker (see undocumentedmatlab example at
  https://undocumentedmatlab.com/blog/javacomponent). When
  selecting a folder, autodetect which tracker the data comes from and
  sampling freq (and e.g. for SMI, notify that you must run idfconverter
  if have not yet done that). User can change detected system (and
  should file a defect)
- file picker: In case of Tobii, read those json files upon folder
  selection, show recording/PP name and such
- file picker: if failed (e.g. wrong folder), outline the problem areas
  in red

# Known issues
- matlab VideoReader (at least in R2017b on Windows 10) cannot read the
  last few frames of some video files, when seeking to a specific time
  of frame, even though it can read them when just reading through the
  file frame by frame. This *appears* to occur for files where the last
  few frames are marked as keyframes in the mp4 stss table, even though
  they are not. All read frames are correct, so not a big problem.

# License details
Most parts of this repository are licensed under the Creative Commons
Attribution 4.0 (CC BY 4.0) license.

# Acknowledgments
mp4 parsing code extracted from https://se.mathworks.com/matlabcentral/fileexchange/28028-mpeg-4-aac-lc-decoder
