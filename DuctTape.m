%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DuctTape is another helper function that handels breaking up
% curves/segmented geometry into evenly spaced points.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x_interpolation, y_interpolation] = DuctTape(X, Y)
    % This part is for the cumulative distance of your geometry...or
    % curve...or whatever else you have in mind, I think this should be
    % universal.
    dx = diff(X);
    dy = diff(Y);

    segment_lengths = hypot(dx, dy);    % Heh heh, bet you didn't expect somethin so simple...oh you did...yeah it is totally obvious.
    cumulative_distance = [0; cumsum(segment_lengths(:))]; % cumsum is cumulative sum. (:) forces segment_lengths into a column vector. The column vector isn't necessary over another type, I just thought vertical stacking would be easiest here. Since 0 is being treated as a scalar [1 x 1], cumsum(segment_lengths) would be a row vector [1 x n] (so it could be [1 2 3 4 5] to 0s [1 x 1]). These shapes just need to match.
    total_length = cumulative_distance(end);

    % Asks you how many points you want in total. Tis optional though.
    if nargin < 3
        answer = inputdlg({'Oi, how many points ya want?'}, 'Total Points', 1, {'100'});
        if isempty(answer)
            x_interpolation = [];
            y_interpolation = [];
            return;
        end
        numpoints = str2double(answer{1});
    end

    % Handles even spacing along curves and normal geometry.
    even_spacing = linspace(0, total_length, numpoints);
    x_interpolation = interp1(cumulative_distance, X, even_spacing);
    y_interpolation = interp1(cumulative_distance, Y, even_spacing);
end
