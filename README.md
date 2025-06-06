# FreePlotDigitizer

This is a lightweight tool for extracting data from images of graphs and plots. Born of the need to use WebPlotDigitizer and the desire to not pay for it. This currently supports linear, logarithmic, and reciprocal axis scaling and is designed for easy modification and flexibility.

## Contents

- [Install](#install)
- [Use](#use)
- [Customization](#customization)

## Install

At the moment, this is just a single matlab script. So long as you have MATLAB, it should work. There's no trick to it, just treat it as a tool. Be nice to it, and it'll take care of you.

## Use

1. **Select file output**: You'll be prompted to choose an a file output in the dropdown menu. Currently supports .csv (Curve) or TXT (Geometry).
2. **Load Image**: You'll select an image of the graph you want to use (png, jpg, tif, gif, mpeg).
3. **Graph Type**: Pick scaling type for X and Y (Linear, Log10, or Reciprocal)
4. **Calibrate Axes**:
   - Click two points on the x axis, minimum to maximum, then enter their corresponding values.
   - Repeat for the y axis
5. **Digitize Points**:
   - **Curve**: Click points along a curve or line within your graph. Each click records a data point.
   - **Geometry**: Click pairs of points to form line segments. After each pair, start exactly where the previous one ended. (So, for example, if you went from (0,5) to (3, 7), your next point should start at (3,7)).
   - Can use backspace/delete to undo points.
6. **Export**:
   - As a .csv, it's saved as (X, Y).
   - In geometry mode, it's saved as a .txt. Segments are saved as (x1  z1  x2  z2  slip_rate)

## Customization

You are more than welcome to use this if you want to (or just tell me how bad it is). I made this to help with research projects, so that's why it's looks and feels frankensteined. If you want to add to this, I tried to make it easily modifiable. Here is how it's structured:

### New Graph Types:
Axis scaling is handled with affine transforms. They are designed such that when you click a point, the raw pixel coordinates of that point are converted to meaningful data. The ones I have built in are Linear, Logarithmic, and Reciprocal. To add a new graph type, you'll want to define another affine transform for the graph type you want, and update the switch cases for both xScale and yScale.

Both axis are calibrated using two points, being pixel location and data value. From there, the affine transforms the pixel coordinates to usable data points within a transformed space (which is your specific graph type). So, for example, the ones I have are done in the format:
  1. Linear:
     ```matlab
     data = ((pixel - p1)/ (p2 - p1)) * (d2 - d1) + d1;
     ```
     Appears as:
     ```matlab
     getLinear = @(v,vData,p) (diff(vData)./diff(p)).*(v-p(1))+vData(1);
     ```
  2. Logarithmic: 
     ```matlab
     data = 10.^(((pixel - p1) / (p2 - p1)) * (log10(d2) - log10(d1)) + log10(d1));
     ```
     Appears as:
     ```matlab
     getLog = @(v,vData,p) 10.^(((v-p(1)).*(log10(vData(2))-log10(vData(1)))./diff(p))+log10(vData(1)));
     ```
  3. Reciprocal:
     ```matlab
     data = 1 ./ (((pixel - p1) / (p2 - p1)) * (1/d2 - 1/d1) + 1/d1);
     ```
     Appears as:
     ```matlab
     getRecip = @(v,vData,p) 1./(((v-p(1)).*(1./vData(2)-1./vData(1))./diff(p))+1./vData(1));
     ```
**Note**: These assume you're working with a simple 2-dimensions x and y graph. It doesn't take into account two y-axes or higher dimensions.

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
   
