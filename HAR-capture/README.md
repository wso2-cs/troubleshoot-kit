# HAR Capture

This contains the instructions to record and capture HAR in different browsers.

- [Reference: HAR Analyzer](https://toolbox.googleapps.com/apps/har_analyzer/)

## Chromium Browsers (incl. Chrome and Edge)

![Chromium HAR Capture](img/Chromium-HAR-NEW.gif) 


1. Right click on the Browser and select `Inspect`
2. Move to the `Network` tab
3. Tick the `Preserve log` option to preserve the network traces. Also tick the `Disable cache`
4. By default, the Network log recording will be on. If not, start the recording by clicking on the round button at the top left corner and make sure it is red
5. Recreate the issue
6. Navigate to Settings > Preferences > Network
7. Enable `Allow to generate HAR with sensitive data`
6. To export and save the HAR file, long-press the `Export HAR` button and select Export HAR (with sensitive data)` option.

## Firefox Broswer

![Firefox HAR Capture](img/Firefox-HAR.gif)

1. Right click on the Browser and select `Inspect`
2. Move to the `Network` tab
3. Tick the `Disable cache`
4. Click on the cogwheel icon and enable the `Persist log`
5. Recreate the issue
6. Save and export the captured, by right-clicking on the grid and choosing `Save All As HAR`, or by clicking the cogwheel icon and `Save All As HAR`
