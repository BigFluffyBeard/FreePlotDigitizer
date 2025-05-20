# FreePlotDigitizer

This is a lightweight tool for extracting data from images of graphs and plots. Born of the need to use WebPlotDigitizer and the desire to not pay for it. This currently supports linear, logarithmic, and reciprocal axis scaling and is designed for easy modification and flexibility.

## Contents

- [Install](#Install)
- [Use](#Use)
- [Customization](#Customization)

## Install

At the moment, this is just a single matlab script. So long as you have MATLAB, it should work. There's no trick to it, just treat it as a tool. Be nice to it, and it'll take care of you.

## Use

The program itself will give you instructions, though it can be a bit finicky (particularly if you're using it for geometry). You'll pick the output file you want and the graph type you need, then upload your image (currently it takes .png, .jpg, .tif, .mpeg, and .gif). It will then ask you to calibrate the axes, starting with the x-axis. You'll click along your axis twice, once for the minimum value and once for the maximum. Then you'll do the same for the y-axis. After this, you can click points along the curve or line you want until you're satisfied. If you're trying it with the fault geometry, two clicks will form a line. So, for example, if you're following a fault with depth, two clicks ill be a line. You start at, say, depth 0, and go to 5 km. To start the next line you'll want to click exactly where your first line ended. Otherwise it'll come out looking weird (it'll show you visually what you've traces afterwards). When you're done, hit enter, and it'll output a data file of whatever type you've selected.

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
