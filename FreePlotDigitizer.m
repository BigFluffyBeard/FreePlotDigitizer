%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a tool for extracting data from graph images, similar to WebPlotDigitizer...except not quite universal.
% At the moment it's designed for curves and linear fault geometry.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FreePlotDigitizer()
    %%% How do you want your data? This asks you how you want it output. For
    %%% my purposes, I have curves and geometry formats. 
    figUI = uifigure('Name', 'Welcome! What are you outputting?','Position',[100 100 350 150]);
    uilabel(figUI,'Position',[20 100 100 20], 'Text','Output:');
    ddMode = uidropdown(figUI,'Position',[120 100 180 20],'Items',{'Curve','Geometry'});
    uibutton(figUI,'push','Text','Next','Position',[120 30 100 30],'ButtonPushedFcn',@(btn,event) uiresume(figUI));
    uiwait(figUI); 
    outputMode = ddMode.Value; 
    close(figUI);


    %%% Now we need to get dat figure. I'll try to make it accepting of all file types
    cancelCounter = 0;
    [fname,path] = uigetfile({'*.png;*.jpg;*.tif;*.mpeg;*.gif','Image Files'},'Pick ur graph!');
    while isequal(fname,0)  % Now don't you be hurtin my digitizer's feelings. Yes, it's 3 am. What's it to ya?
        cancelCounter = cancelCounter + 1;
        if cancelCounter == 2
            msgbox("I'm starting to take this personally.")
        elseif cancelCounter > 2
            msgbox('I need some coffee.')
            return; 
        end
    end
    img = imread(fullfile(path, fname));
    fig = figure;
    imshow(img);
    hold on;

    
    %%% Axes format options (tried to make it easy to add more). On another
    %%% note...I'm not entirely sure why there's a select all button...but
    %%% I wouldn't click it.
    scaleOptions = {'Linear','Log10','Reciprocal'};
    [xScaleIdx, okX] = listdlg('PromptString','X-axis scale:','ListString',scaleOptions);
    if ~okX
        return; 
    end
    [yScaleIdx,okY] = listdlg('PromptString','Y-axis scale:','ListString',scaleOptions);
    if ~okY
        return; 
    end
    xScale = scaleOptions{xScaleIdx};
    yScale = scaleOptions{yScaleIdx};


   %%% Now we gotta calibrate them axes.
    while true
        title('Click two points on the x-axis (min to max)');
       
        % Get figure and axis handles
        fig = gcf;
        ax = gca;
    
        % Create line objects for the crosshairs
        hl = line(ax, [NaN NaN], [NaN NaN], 'Color', 'm', 'LineStyle', '-', 'LineWidth', 1); % Horizontal
        vl = line(ax, [NaN NaN], [NaN NaN], 'Color', 'm', 'LineStyle', '-', 'LineWidth', 1); % Vertical
        set(gcf, 'Pointer', 'custom', 'PointerShapeCData', NaN(16), 'PointerShapeHotSpot', [1, 1]);
    
        % Attach motion callback
        set(fig, 'WindowButtonMotionFcn', @(~,~) updateCrosshair());
    
        px_raw = Pylon('X-axis calibration', 2);
        px = px_raw(:, 1);  % only take x-coordinates from pylon
        xInput = inputdlg({'x-axis [min max]'}, 'x calibration', 1, {'0 1'});
        if isempty(xInput)
            return;
        end
        Xvals = sscanf(xInput{1}, '%f %f');
    
        title('You know the drill, Same thing, but for the y-axis.');
        
        py_raw = Pylon('Y-axis Calibration', 2);
        py = py_raw(:, 2);   % only take y coordinates from pylon
        yInput = inputdlg({'y-axis [min to max]'}, 'Y calibration', 1, {'0 1'});
        if isempty(yInput)
            return;
        end
        Yvals = sscanf(yInput{1}, '%f %f');

        userChoice = questdlg('Oi! You sure about that?', 'Axis Calibration', 'Redo', 'Continue', 'continue');
        if strcmp(userChoice , 'Redo')
            continue;
        elseif strcmp(userChoice, 'Continue')
            break;
        else
            break;
        end 
    end

    % This handles the big crosshair reticles that follow your cursor
    % around when calibrating.
    function updateCrosshair()
        cp = get(ax, 'CurrentPoint');
        x = cp(1,1);
        y = cp(1,2);

        % Get axis limits
        xlim_ = xlim(ax);
        ylim_ = ylim(ax);

        % Update line positions
        set(hl, 'XData', xlim_, 'YData', [y y]); % Horizontal line
        set(vl, 'XData', [x x], 'YData', ylim_); % Vertical line
    end

    %%% Now time for the affiines. Unless you want to add another graph
    %%% type, you can just ignore these. You'll need to figure out the affine
    %%% transform for your specific graph type. If you like
    %%% doing these kinds of things, my affines are translation + scale
    %%% transforms...they pretty much take the form of y = mx + b.
    
    getLinear = @(v,vData,p) (diff(vData)./diff(p)).*(v-p(1))+vData(1);
    getLog = @(v,vData,p) 10.^(((v-p(1)).*(log10(vData(2))-log10(vData(1)))./diff(p))+log10(vData(1)));
    getRecip = @(v,vData,p) 1./(((v-p(1)).*(1./vData(2)-1./vData(1))./diff(p))+1./vData(1));
    
    switch xScale
        case 'Linear', mapX = @(v) getLinear(v,Xvals,px);
        case 'Log10', mapX = @(v) getLog(v, Xvals,px);
        case 'Reciprocal', mapX = @(v) getRecip(v,Xvals,px);
    end
    switch yScale
        case 'Linear', mapY = @(v) getLinear(v,Yvals,py);
        case 'Log10', mapY = @(v) getLog(v, Yvals, py);
        case 'Reciprocal', mapY = @(v) getRecip(v, Yvals, py);
    end

    %%% Now time for the hard parts. Digitization parameters first
    x_pixel = []; y_pixel = []; h = [];
    set(fig,'WindowButtonDownFcn', @click_callback);
    set(fig,'KeyPressFcn',@key_callback);
    title('Looks like it"s time to click some points, lil" bro. (Press Enter to finish, backspace/Delete to undo)');
    waitfor(fig,'UserData','done');
    set(fig,'WindowButtonDownFcn','');
    set(fig,'KeyPressFcn','');

    %%% MMMappin and savin time. This part is a bit of an eyesore.
    
    X = mapX(x_pixel); Y = mapY(y_pixel);
    % answer = questdlg('Save as curve (CSV) or geometry (TXT)? Or you could edit this to put in your own output, I tried to make it easy.','Output format','Curve (CSV)', 'Geometry (TXT','Curve(CSV)');
    if strcmp(outputMode, 'Curve')
        T = table(X(:),Y(:),'VariableNames',{'X','Y'});
        [ofn,op]=uiputfile('*.csv','Save Curve As'); 
        if isequal(ofn,0)
            return; 
        end
        writetable(T,fullfile(op,ofn));
    else
        [ofn,op]=uiputfile('*.txt','Save Geometry As'); 
        if isequal(ofn,0)
            return; 
        end
        fid=fopen(fullfile(op,ofn),'w'); fprintf(fid,'# x1\tz1\tx2\tz2\tslip_rate\n');
        
        choice = questdlg('Oi? You want evenely spaced points across your trace?', 'Resample Geometry?', 'Yes', 'No', 'No');

        if strcmp(choice, 'Yes')
            [X, Y] = DuctTape(X, Y);    % Mythbusters were right afterall.
            sliprate = str2double(inputdlg({'Slip rate for all segments:'}, 'Slip Rate', 1, {'0'}));

            for i = 1:length(X) - 1
                x1 = X(i); y1 = Y(i);
                x2 = X(i + 1); y2 = Y(i + 1);

                fprintf(fid, '%.4f\t%.4f\t%.4f\t%.4f\t%.2f\n', x1, y1, x2, y2, sliprate);
            end
        end
        fclose(fid);
    end
    hold off;

    %%% Now time for some nested callbacks. These handle user inputs within
    %%% the ui. Clicking points, undoing points, etc...
    function click_callback(~,~)
        cp = get(gca,'CurrentPoint');
        x_pixel(end+1)=cp(1,1); y_pixel(end+1)=cp(1,2);
        h(end+1)=plot(cp(1,1),cp(1,2),'r+','MarkerSize',8);
    end
    function key_callback(~,event)
        switch event.Key
            case {'backspace','delete'}
                if ~isempty(x_pixel)
                    x_pixel(end)=[]; y_pixel(end)=[]; delete(h(end)); h(end)=[];
                end
            case 'return'
                set(fig,'UserData','done');
        end
    end
end

