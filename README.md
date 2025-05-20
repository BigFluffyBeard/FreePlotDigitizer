# FreePlotDigitizer

This is a lightweight tool for extracting data from images of graphs and plots. Born of the need to use WebPlotDigitizer and the desire to not pay for it. This currently supports linear, logarithmic, and reciprocal axis scaling and is designed for easy modification and flexibility.

## Contents

- [Install](#Install)
- [Use](#Use)
- [Customization](#Customization)

## Install

At the moment, this is just a single matlab script. So long as you have MATLAB, it should work. There's no trick to it, just treat it as a tool. Be nice to it, and it'll take care of you.

## Use

1. **Select file output**: You'll be prompted to choose an a file output.
2. **Load Image**: You'll select an image of the graph you want to use (png, jpg, tif, gif, mpeg).
3. **Graph Type**: Pick scaling type for X and Y (Linear, Log10, or Reciprocal)
4. **Calibrate Axes**:
   - Click two points on the x axis, minimum to maximum, then enter their corresponding values.
   - Repeat for the y axis
5. **Digitize Points**:
   - **Curve**: Click points along a curve or line within your graph. Each click records a data point.
   - **Geometry**: Click pairs of points tto form line segments. After each pair, start exactly where the previous one        ended. (So, for example, if you went from 0 to 5, your next point should start at 5).
   - Can use backspace/delete to undo points.
6. **Export**:
   - As a .csv, it's saved as (X, Y).
   - In geometry mode, it's saved as a .txt. Segments are saved as (x1  z1  x2  z2  slip_rate)

## Customization

You are more than welcome to use this if you want to (or just tell me how bad it is). I made this to help with research projects, so that's why it's looks and feels frankensteined. If you want to add to this, I tried to make it easily modifiable. Here is how it's structured:

New Graph Types:
Axis scaling is handled with affine transforms. They are designed such that when you click a point, the raw pixel coordinates of that point are converted to meaningful data. The ones I have built in are Linear, Logarithmic, and Reciprocal. To add a new graph type, you'll want to define another affine transform for the graph type you want, and update the switch cases for both xScale and yScale.

Both axis are calibrated using two points, being pixel location and data value. The affine can be devised based on this. So, for example, the ones I have are done by:
  Linear: data = a * pixel + b
  Logarithmic: data = log10(a * pixel + b)
  Reciprocal: data = 1/(a * pixel + b)

File exports:
If you want to add a file output type, you'll want to modify the conditional block that handles outputMode. You'll want to add a new outputMode option where the use selects the file export, and insert a new elseif branch in the output block (which is right after strcmp(outputMode, 'Curve')). Once you do that you should be good to go!
