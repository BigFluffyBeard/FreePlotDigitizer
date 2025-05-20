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

### New Graph Types:
Axis scaling is handled with affine transforms. They are designed such that when you click a point, the raw pixel coordinates of that point are converted to meaningful data. The ones I have built in are Linear, Logarithmic, and Reciprocal. To add a new graph type, you'll want to define another affine transform for the graph type you want, and update the switch cases for both xScale and yScale.

Both axis are calibrated using two points, being pixel location and data value. The affine can be devised based on this. So, for example, the ones I have are done in the format:
  1. Linear: data = a * pixel + b
     Appears as:
     ```matlab
     getLinear = @(v,vData,p) (diff(vData)./diff(p)).*(v-p(1))+vData(1);
     ```
  3. Logarithmic: data = log10(a * pixel + b)
     Appears as:
     ```matlab
     getLog = @(v,vData,p) 10.^(((v-p(1)).*(log10(vData(2))-log10(vData(1)))./diff(p))+log10(vData(1)));
     ```
  5. Reciprocal: data = 1/(a * pixel + b)
     Appears as:
     ```matlab
     getRecip = @(v,vData,p) 1./(((v-p(1)).*(1./vData(2)-1./vData(1))./diff(p))+1./vData(1));
     ```

### Adding File exports:

1. You'll want to extend the outputMode selection by adding your file type to the list of options.
2. Then you'll want to insert a new elseif in the export block.
   Example for JSON:
   ```matlab
     elseif strcmp(outputMode,'JSON')
     [ofn,op]=uiputfile('*.json','Save JSON As');
     data = struct('X',X,'Y',Y);
     jsonText = jsonencode(data);
     fid = fopen(fullfile(op,ofn),'w');
     fprintf(fid,'%s',jsonText);
     fclose(fid);
   ```
   
