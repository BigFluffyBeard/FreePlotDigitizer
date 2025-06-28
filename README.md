# FreePlotDigitizer

This is a lightweight tool for extracting data from images of graphs and plots. Born of the need to use WebPlotDigitizer and the desire to not pay for it. This currently supports linear, logarithmic, and reciprocal axis scaling and is designed for easy modification and flexibility.

## Contents

- [Install](#install)
- [Use](#use)
- [Customization](#customization)
- [DuctTape.m](#DuctTape.m)

## Install

At the moment, this tool consists of the main script, Ducttape.m and Pylon.m. There's no real trick here. Just make sure they're all in the same directory and you should be good to go.

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

## DuctTape.m
Coming into this script we have a list of an N amount of (x, y) points that were manually picked along a curve. Unless you're a god, these points are going to be irregular. It is the job of DuctTape.m to take these irregularly-sampled points and output a new set of N points evenly spaced along your curve/line.

Starting off, think of the length between two points on your curve as segments. So point (1, 2) to (3, 5) would be treated as a segment. What we can do is acquire the run of the segment (by which I mean distance traveled along the x-axis) by doing the following:
   ```math
   \Delta x_i = x_{i+1} - x_i , \space \space \Delta y_i = y_{i + 1} - y_i
   ```
The total length of the segment formed by these two points can be acquired via the pythagorean theorem:
   ```math
   l_i = \sqrt{(x_{i + 1} - x_i)^2 + (y_{i + 1} - y_i)^2}
   ```
Basically, you'll have the distance along your segment/curve as a straight line with this. The code looks like this:
   ```matlab
   dx = diff(X);
   dy = diff(Y);
   segment_lengths = hypot(dx, dy);
   ```
Now we need some way to account for the total distance traveled (a straight line doesn't accurately describe a curve). To do this, we can use Matlab's cumulative sum (cumsum) function. Idally we're working with more than one segment here. Given this, we can define a vector of segment lengths:
   ```math
   l_i = [l_1, \space l_2, \space l_3, ..., l_n]
   ```
We can take the length of these segments and sum over all of them for the total distance travelled along the curve:
   ```math
   cumulative distance = [l_1, \space l_1 + l_2, \space l_1 + l_2 + l_3, \space l_1 + l_2 + ... + l_n]
   ```
In matlab this looks like:
   ```matlab
   cumulative_distance = [0; cumsum(segment_lengths(:))];
   ```
With all of these euclidean calculations we're doing, it so happens that we can happily happen upon a parameter for arclength. Mathematically, this looks like:
   ```math
   s_i = \sum_{k = 1}^{i - 1} l_k, \space \space s_1 = 0, \space s_n = L
   ```
Where `L` is the total length of the arc-length segment. In matlab:
   ```matlab
   total_length = cumulative_distance(end);
   ```
Each arclength parameter corresponds to the total distance along a segment bounded by two points `(x_1, y_1)` and `(x_2, y_2)`. So this means that the first parameter `s_1 = 0` due to it not having the opportunity to travel yet. When you get to the second parameter, it will be `s_2 = l_1`, then `s_3 = l_1 + l_2` ...and so on. With this in mind, we can set up a vector for arc length:
   ```math
   s = [s_1, \space s_2, \space ... , \space s_n]
   ```
Now that we have all of this information about our curve, we can start to ask questions about it. Now I know one you're wondering. "How can we get a set amount of evenly-spaced points across our curve?" Well I'm glad you asked!

First we need to be able to define evenly-space positions along our entire curve based on a set amount of points. If we want `N` number of points over our total length `L`, we can just multiply our total length by the specific position we're interested in (let's call that `j`) and divide it by our desired number of points.
   ```math
   s_j = \frac{(j - 1)L}{(N - 1)} , \space \space from \space \space j = 1 \space \space to \space \space N
   ```
In matlab, this looks like:
   ```matlab
   even_spacing = linspace(0, total_length, numpoints);
   ```
With this, we can acquire the (x,y) coordinates of our position `j` using linear interpolation. Matlab can handle this like so:
   ```matlab
   x_interpolation = interp1(cumulative_distance, X, even_spacing);
   y_interpolation = interp1(cumulative_distance, Y, even_spacing);
   ```
If that doesn't satisfy you, here is what this is doing:
   ```math
   x_j = x_i + \frac{(s_j - s_i)}{(s_{i + 1} - s_i)}(x_{i + 1} - x_i)
   ```
   ```math
   y_j = y_i + \frac{(s_j - s_i)}{(s_{i + 1} - s_i)}(y_{i + 1} - y_i)
   ```
Given that our arclength is based off of our manually-selected points, what we can do is use them as a sort of base. Position `j` will fall within some segment bounded by som `x_i` and `y_i`. However, now that we're deeling with an arc-length parameter...we need some way to account for this. We can say our position along our arclength when getting evenly spaced points will be `s_j - s_i`, and that any number of points `N` will be under the bounds `s_{i+1} - s_i`. With all of this in mind, now an evenly spaced coordinate `(x_j, \space y_j)` is given by the above two equations.








