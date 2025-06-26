%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a helper function that allows the user to click an n amount of points on an
% image, then storing them in an array. I called this Pylon because you
% must click additional points.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function points = Pylon(promptTitle, n)
    % Create figure (assuming the figure/image is already up), and prompt user to click n amount of points
    disp([promptTitle ': Click ' num2str(n) ' points...']);

    % points array. Stores n points in columns
    points = zeros(n, 2);
    i = 1;

    hFig = gcf; % Using the current figure
    set(hFig, 'WindowButtonDownFcn', @getClick);    % WindowButtonDownFcn is the big boss...you can't get around this without a complete re-write of the whole script...it beat me down...it even beat chat gpt down...

    % Pauses script execution until this box is closed.
    uiwait(msgbox(sprintf('Click %d points. Press Enter if needed. Click points while this message box is up. It will assume you"re done if you close this.', n), promptTitle));

    % tracks each mouse click and stores them in the points array
    function getClick(~, ~)
        cp = get(gca, 'CurrentPoint');
        points(i, :) = cp(1, 1:2);
        hold on;
        plot(cp(1,1), cp(1,2), 'rx', 'MarkerSize', 8);
        i = i + 1;

        if i > n
            set(hFig, 'WindowButtonDownFcn', '');
            uiresume(hFig);
        end
    end
end
