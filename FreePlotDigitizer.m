%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Since Webplot Digitizer went and monopolized...I'll just make my own
% digitizer...shouldn't be that hard, right?.....right? This pretty much
% forces image pixels into the graph type format using affine transfrorms, and then outputs it to a file of your choosing (right now it's set for curves and geometry). 
% It should be compatable with...any graph type... think. I tested it wth a Galilean type and it
% worked perfectly. The geometry output takes a bit to get used to.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FreePlotDigitizer()
    % How do you want your data? This asks you how you want it output. For
    % my purposes, I have curves and geometry formats. 
    figUI = uifigure('Name', 'Welcome! What are you outputting?','Position',[100 100 350 150]);
    uilabel(figUI,'Position',[20 100 100 20], 'Text','Output:');
    ddMode = uidropdown(figUI,'Position',[120 100 180 20],'Items',{'Curve','Geometry'});
    uibutton(figUI,'push','Text','Next','Position',[120 30 100 30],'ButtonPushedFcn',@(btn,event) uiresume(figUI));
    uiwait(figUI); 
    outputMode = ddMode.Value; 
    close(figUI);


    % Now we need to get dat figure. I'll try to make it accepting of all file types
    cancelCounter = 0;
    [fname,path] = uigetfile({'*.png;*.jpg;*.tif;*.mpeg;*.gif','Image Files'},'Pick ur graph!');
    while isequal(fname,0)  % Now don't you be hurtin my digitizer's feelings. Yes, it's 3 am. What's it to ya?
        cancelCounter = cancelCounter + 1;
        if cancelCounter == 2
            msgbox('I"m starting to take this personally.')
        elseif cancelCounter > 2
            msgbox('I need some coffee.')
            return; 
        end
    end
    img = imread(fullfile(path, fname));
    fig = figure;
    imshow(img);
    hold on;

    
    % Axes format options (tried to make it easy to add more). On another
    % note...I'm not entirely sure why there's a select all button...but
    % I wouldn't click it.
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


    % Now we gotta calibrate dem axes.
    title('Click two points on the x-axis (min to max)');
    [px, ~] = ginput(2);
    xInput = inputdlg({'x-axis [min max]'}, 'x calibration',1,{'0 1'});
    if isempty(xInput)
        return;
    end
    Xvals = sscanf(xInput{1}, '%f %f');
    title('You know the drill, Same thing, but for the y-axis.');
    [~, py] = ginput(2);
    yInput = inputdlg({'y-axis [min to max]'}, 'Y calibration',1,{'0 1'});
    if isempty(yInput)
        return;
    end
    Yvals = sscanf(yInput{1}, '%f %f');

    % Now time for the affiines. Unless you want to add another graph
    % type, you can just ignore these. You'll need to figure out the affine
    % transform for your specific graph type. If you like
    % doing these kinds of things, my affines are translation + scale
    % transforms...they pretty much take the form of y = mx + b.
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

    % Now time for the hard parts. Digitization parameters first
    x_pixel = []; y_pixel = []; h = [];
    set(fig,'WindowButtonDownFcn', @click_callback);
    set(fig,'KeyPressFcn',@key_callback);
    title('Looks like it"s time to click some points, lil" bro. (Press Enter to finish, backspace/Delete to undo)');
    waitfor(fig,'UserData','done');
    set(fig,'WindowButtonDownFcn','');
    set(fig,'KeyPressFcn','');

    % MMMappin and savin time. This part is a bit of an eyesore
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

        % This loops over each segment. Every pair of points is treated as a segment.
        for k=1:2:length(X)
            prompt = {sprintf('Slip rate for the segment %df:', (k+1) / 2), 'How many points do you want in each segment?'};
            defans = {'0', '0'};    % Default values
            resp = inputdlg(prompt, 'Segment Parameters', 1, defans);

            if isempty(resp)
                break;
            end

            % Casts string inputs to numerical values
            sliprate = str2double(resp{1});    % Slip rate isn't necessary, it's just helpful to me.
            nInterp = str2double(resp{2});

            % Stores start and end points
            x1 = X(k); x2 = X(k + 1);
            y1 = Y(k); y2 = Y(k + 1);

            % Linear interpolation between start and endpoints. Returns the amount of points the user specified in each segment.
            for i = 0: nInterp + 1
                t = i / (nInterp + 1);
                xi = x1 + t * (x2 - x1);
                yi = y1 + t * (y2 - y1);

                % Saves each point found this way
                fprintf(fid, '%.4f\t%.4f\t%.4f\t%.4f\t%.2f\n', xi, yi, xi, yi, sliprate);
            end
        end
        fclose(fid);
    end
    hold off;

    % Now time for some nested callbacks. These handle user inputs within
    % the ui. Clicking points, undoing points, etc...
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

