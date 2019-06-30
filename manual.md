# Manual GlassesViewer

## 1 - Opening a Tobii Pro Glasses 2 recording in glassesViewer

First, open MATLAB and open glassesViewer.m in the editor.

![](screenshots/001.png)

When you run glassesViewer.m, a pop-up asks you to select the projects folder of the SD card on which your recordings are placed. Navigate to the projects folder and click "Select folder". For this example, choose the `demo_data` directory included in this repository.

![](screenshots/002.png)

A second pop-up asks you to select the recording that you wish to open in glassesViewer. Recordings are organized by study and participant. First select the study.

![](screenshots/003.png)

Next, select the participant.

![](screenshots/004.png)

Finally select the recording and click "Use selected recording".

![](screenshots/005.png)

When reading the recording, glassesViewer produces some output in the MATLAB command window, among which several measures of eye-tracking data quality.

![](screenshots/006.png)

## 2 - The glassesViewer interface

Once the recording is loaded, the glassesViewer interface opens.

![](screenshots/007.png)

The amount of visible data can be changed by dragging the sliders on the timeline underneath the scene video.

![](screenshots/008.png)

Pressing the Settings button opens a panel with various interface configuration options.

![](screenshots/009.png)

Using this panel, one can for instance modify which data stream plots should be shown.

![](screenshots/010.png)

Browse through the data:

![](screenshots/011.png)

## 3 - Fixation classification

Click on the lowest event stream in the scarf plot underneath the first data stream plot on the left of the interface. This makes the selected event stream active, meaning that its codes are displayed by means of highlighting in each of the data stream plots.

![](screenshots/012.png)

The current settings of the slow phase / fast phase classifier algorithm do not appear ideal as some clear saccades are not labeled as fast phase. To change the classifier's settings, click the Classifier settings button.
If multiple classifier event streams are defined, clicking this button brings up a dialog where you chose the classifier for which you want to change the settings. Select the Hessels et al. (2019) one for this example.

![](screenshots/013.png)

This opens the classifier settings dialog.

![](screenshots/014.png)

Change the lambda threshold and click recalculate.

![](screenshots/015.png)

When a new event coding is produced, it is updated in the interface. The red Save coding button indicates this new event classification has not been saved to file yet.

![](screenshots/016.png)

Press Save coding to save it to the recording's coding.mat file. When the coding is saved, the button turns green.

![](screenshots/017.png)

## 4 - Manual annotation of eye-tracking data

Click on the second event stream in the event stream scarf, it is currently empty. Then click somewhere in a data stream plot to make the first annotation. On the dialogue box that opens, select the category to annotate the marked episode with.

![](screenshots/018.png)

The code is now applied.

![](screenshots/019.png)

Click further in the stream to add a second event code of a different kind:

![](screenshots/020.png)

Drag the edge of an annotation to adjust its duration:

![](screenshots/021.png)

Add some more event code:

![](screenshots/022.png)

## 5 - exiting GlassesViewer

When exiting glassesViewer, if the coding currently displayed is not saved, a dialog box will appear asking whether to save adjusted coding or not:

![](screenshots/023.png)

# Integration with GazeCode

GlassesViewer furthermore offers a close integration with [GazeCode](https://github.com/jsbenjamins/gazecode). Below we document how GazeCode is used for manual mapping of the participant's fixations onto the visual stimulus. Please refer to GazeCode's manual for a complete description of GazeCode's functionality.

# 1 - opening the recording in GazeCode.
TODO
