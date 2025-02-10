function TDLITE_RBlock(app)

%% Clear command window and close any figures

clc;
clear;
close all;

%% 

% Picoscope Settings Setup
AUTO_TRIG_MS = 300;
TRIGLEVEL_MV = 3000;
TIMEBASE     = 1000;                                       % Sampling Rate = 80 MHz / (n+1)
                                                        % Sampling Interval = 80 MHz * (n+1)  

% Settings
FNames = {}; 
Count = {};
nChannels = 2;

if nargin == 0
    app.sn_current = '';
    app.n_ch = 6;
    app.n_tx = 4;
    app.holdoff_s = 100e-6;
    app.off_time_s = 20e-3;%8.33e-3;
    app.fs = 10e6;
    app.n_bins = 30;
    app.bkg_stack = 10;
    app.T_s = 33.33e-3;
    app.dt = 1/app.fs;
    app.connected = true;
    app.fileout = 'data.mat';
end

try 
    % buff_cycles = 5;
    PRETRIG1_S  = 1000;
    % POSTTRIG1_S = floor(app.T_s * app.fs * buff_cycles);
    % T_S         = ceil(app.T_s/app.dt);             % samples per tx period
    % decay_S     = ceil(T_S/4);                      % number of samples in a decay
    
    %% Load configuration information

    % % Setup paths and also load struct and enumeration information. Enumeration
    % % values are required for certain function calls.
    % 
    % [~, ps4000aEnuminfo] = ps4000aSetConfig(); % DO NOT EDIT THIS LINE.

    PS4000aConfig;
    
    %% Device connection

    % Check if an Instrument session using the device object 'ps4000aDeviceObj'
    % is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
    if (exist('ps4000aDeviceObj', 'var') && ps4000aDeviceObj.isvalid && strcmp(ps4000aDeviceObj.status, 'open'))
        
        openDevice = questionDialog(['Device object ps4000aDeviceObj has an open connection. ' ...
            'Do you wish to close the connection and continue?'], ...
            'Device Object Connection Open');
        if (openDevice == PicoConstants.TRUE)
            
            % Close connection to device
            disconnect(ps4000aDeviceObj);
            delete(ps4000aDeviceObj);  
        else
    
            % Exit script if User 
            return;        
        end  
    end

    % Create a device object. 
    % The serial number can be specified as a second input parameter.
    pscope1 = icdevice('picotech_ps4000a_generic.mdd', '');
    
    % Connect device object to hardware.
    connect(pscope1);
    
    %% Set channels
    
    % Default driver settings applied to channels are listed below - 
    % use |ps4000aSetChannel()| to turn channels on or off and set voltage ranges, 
    % coupling, as well as analog offset.
    %
    % In this example, data is only collected on Channel A so default settings
    % are used and other input channels are switched off.
    %
    % If using the PicoScope 4444, select the appropriate range value for the
    % probe connected to an input channel using the enumeration values
    % available from the |ps4000aEnuminfo.enPicoConnectProbeRange| substructure.
    
    % Channels       : 1 - 7 (ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_B - PS4000A_CHANNEL_H)
    % Enabled        : 0
    % Type           : 1 (ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC)
    % Range          : 8 (ps4000aEnuminfo.enPS4000ARange.PS4000A_5V)
    % Analogue Offset: 0.0
   
    % Execute device object function(s).
    [status1.setChA] = invoke(pscope1, 'ps4000aSetChannel', 0, 1, 1, 10, 0.0);
    [status1.setChB] = invoke(pscope1, 'ps4000aSetChannel', 1, 1, 1, 8, 0.0);
    % [status1.setChC] = invoke(pscope1, 'ps4000aSetChannel', 2, 0, 1, 1, 0.0);
    % [status1.setChD] = invoke(pscope1, 'ps4000aSetChannel', 3, 0, 1, 1, 0.0);
    % [status1.setChE] = invoke(pscope1, 'ps4000aSetChannel', 4, 0, 1, 1, 0.0);
    % [status1.setChF] = invoke(pscope1, 'ps4000aSetChannel', 5, 0, 1, 1, 0.0);
    % [status1.setChG] = invoke(pscope1, 'ps4000aSetChannel', 6, 0, 1, 1, 0.0);
    % [status1.setChH] = invoke(pscope1, 'ps4000aSetChannel', 7, 0, 1, 1, 0.0);

    % Obtain the channel range and units
    [chAInputRange, chAUnits] = invoke(pscope1, 'getChannelInputRangeAndUnits', ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_A);
    [chBInputRange, chBUnits] = invoke(pscope1, 'getChannelInputRangeAndUnits', ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_B);

    %% Set memory segments and number of samples per channel/segment
    
    % Configure number of memory segments and query |ps4000aGetMaxSegments()| to
    % find the maximum number of samples for each segment.
    
    nSegments = 4096;
    %[status1.GetMaxSegments, maxSegments] = invoke(pscope1, 'ps4000aGetMaxSegments');
    
    [status1.MemorySegments, nMaxSamples] = invoke(pscope1, 'ps4000aMemorySegments', nSegments);

    fprintf('Max Samples: %d\n', nMaxSamples);

    % Set the number of pre- and post-trigger samples to collect per channel
    % for each waveform. Ensure that the total does not exceed |nMaxSamples|
    % above.

    POSTTRIG1_S = (nMaxSamples - PRETRIG1_S);

    % This is the total number over all channels, so if more than one channel is in use, 
    % the number of samples available to each channel is nMaxSamples divided by 2 (for 2 channels) 
    % or 4 (for 3 or 4 channels) or 8 (for 5 to 8 channels).
    if nChannels == 1
        nDivide = 1;
    elseif nChannels == 2 
        nDivide = 2;
    elseif nChannels == 3 || nChannels == 4
        nDivide = 4;
    elseif  nChannels >= 5
        nDivide = 8;
    end
    
    % Set pre-trigger and post-trigger samples as required
    set(pscope1, 'numPreTriggerSamples', (PRETRIG1_S / nDivide));
    set(pscope1, 'numPostTriggerSamples', (POSTTRIG1_S / nDivide));
    
    %% Verify timebase index and maximum number of samples
    
    % Driver default timebase index used - use |ps4000aGetTimebase2()| to query the
    % driver as to suitability of using a particular timebase index and the
    % maximum number of samples available in the segment selected (the buffer
    % memory has not been segmented in this example) then set the |timebase|
    % property if required.
    %
    % To use the fastest sampling interval possible, set one analog channel
    % and turn off all other channels.
    
    status1.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
    timebaseIndex = TIMEBASE;
    
    while (status1.getTimebase2 == PicoStatus.PICO_INVALID_TIMEBASE)
    
        [status1.getTimebase2, timeIntervalNanoSeconds, maxSamples] = invoke(pscope1, ...
            'ps4000aGetTimebase2', timebaseIndex, 0);
        if (status1.getTimebase2 == PicoStatus.PICO_OK)
           
            break; 
        else
            
            timebaseIndex = timebaseIndex + 1;
        end
    end
    
    fprintf('Max Samples: %d\n', maxSamples);
    fprintf('Timebase index: %d\n', timebaseIndex);
    set(pscope1, 'timebase', timebaseIndex);
    
    %% Set simple trigger
    
    % Set a trigger on Channel A, with an auto timeout - the default value for
    % delay is used.
    
    % Trigger properties and functions are located in the Instrument
    % Driver's Trigger group.
    
    trig1 = get(pscope1, 'Trigger');
    trig1 = trig1(1);
    
    % Set the |autoTriggerMs| property in order to automatically trigger the
    % oscilloscope after 1 second if a trigger event has not occurred. Set to 0
    % to wait indefinitely for a trigger event.
    
    set(trig1, 'autoTriggerMs', AUTO_TRIG_MS);
    
    % Channel     : 0 (ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_A)
    % Threshold   : 500 (mV)
    % Direction   : 2 (ps4000aEnuminfo.enPS4000AThresholdDirection.PS4000A_RISING)
    
    [status1.setSimpleTrigger] = invoke(trig1, 'setSimpleTrigger', 1, TRIGLEVEL_MV, 2);
    
    %% Setup rapid block parameters and capture data

    % Capture a set of rapid block data and retrieve data values for Channel A.
    % Rapid Block specific properties and functions are located in the Instrument
    % Driver's Rapidblock group.
    
    rapidBlock1 = get(pscope1, 'Rapidblock');
    rapidBlock1 = rapidBlock1(1);
    
    % Set the number of waveforms to captures
    
    nCaptures = 16;
    [status1.setNoOfCaptures] = invoke(rapidBlock1, 'ps4000aSetNoOfCaptures', nCaptures);
    
    % Block specific properties and functions are located in the Instrument
    % Driver's Block group.
    
    block1 = get(pscope1, 'Block');
    block1 = block1(1);

    while app.connected

        bckgAnswer = questdlg("Collect Background?", "Background", "Yes", "No", "Yes");
        
        switch bckgAnswer
            case 'Yes'
        
                prompt = {'Enter Datashot Type:'};
                dlgtitle = 'Input';
                fieldsize = [1 45];
                definput = {'Bkg'};
                answer = inputdlg(prompt, dlgtitle, fieldsize, definput);
        
                mkdir(answer{1})
                currFolder = [pwd, '\', answer{1}];

                % Append File Names
                FNames = [FNames; answer{1}];

                % Get Today's Date
                %datetime('now', 'TimeZone', 'local','Format', 'yyyyMMdd')
        
                i = 1;

                hWaitBar = waitbar(0, '', 'Name', 'Stop Data Collection', 'CreateCancelBtn', 'delete(gcbf)');
                
                while true

                    % Update the wait bar
                    waitbar(i, hWaitBar, ['Bkg: ', num2str(i)])
        
                    app.fileout = [currFolder, '\', answer{1}, '_', num2str(i) , '.mat'];
            
                    % tL = javaMethod('currentTimeMillis','java.lang.System');        % loop timer
                    [status1.runBlock] = invoke(block1, 'runBlock', 0);
                    [numSamples, ~, chA, chB] = invoke( ...
                        rapidBlockGroupObj, 'getRapidBlockData', numCaptures, 1, 0);
            
                    % tB = javaMethod('currentTimeMillis','java.lang.System');        % loop timer
                    save(app.fileout, 'ch*', 'timeIntervalNanoSeconds', 'numSamples');
            
                    pause(.09);
        
                    i = i + 1;

                    if ~ishandle(hWaitBar)

                        Count = [Count; (i - 1)];

                        % Stop the if cancel button was pressed
                        disp('Stopped By User');
                        disp([ num2str(i - 1) ' Background Shots Were Taken']);
                        break;
                    end
                end

            case 'No'
        end

        while true

            dataAnswer = questdlg("Collect Data?", "Data", "Yes", "No", "Yes");
            
            switch dataAnswer
                case 'Yes'
            
                    prompt = {'Enter Datashot Type:'};
                    dlgtitle = 'Input';
                    fieldsize = [1 45];
                    definput = {''};
                    answer = inputdlg(prompt, dlgtitle, fieldsize, definput);
            
                    mkdir(answer{1})
                    currFolder = [pwd, '\', answer{1}];

                    % Append File Names
                    FNames = [FNames; answer{1}];
    
                    % Get Today's Date
                    %datetime('now', 'TimeZone', 'local','Format', 'yyyyMMdd')
            
                    i = 1;

                    hWaitBar = waitbar(0, '', 'Name', 'Stop Data Collection', 'CreateCancelBtn', 'delete(gcbf)');
                    
                    while true
    
                        % Update the wait bar
                        waitbar(i, hWaitBar, ['Data: ', num2str(i)])
            
                        app.fileout = [currFolder, '\', answer{1}, '_', num2str(i) , '.mat'];
                
                        % tL = javaMethod('currentTimeMillis','java.lang.System');        % loop timer
                        [status1.runBlock] = invoke(block1, 'runBlock', 0);
                        [numSamples, ~, chA, chB] = invoke( ...
                        rapidBlockGroupObj, 'getRapidBlockData', numCaptures, 1, 0);
                
                        % tB = javaMethod('currentTimeMillis','java.lang.System');        % loop timer
                        save(app.fileout, 'ch*', 'timeIntervalNanoSeconds', 'numSamples');
                
                        pause(.09);
            
                        i = i + 1;
    
                        if ~ishandle(hWaitBar)

                            Count = [Count; (i - 1)];
    
                            % Stop the if cancel button was pressed
                            disp('Stopped By User');
                            disp([ num2str(i - 1) ' Background Shots Were Taken']);
                            break;
                        end
                    end
    
                case 'No'
                    break
            end
        end

        app.connected = false;
    end

    settings = table(FNames, Count);
    save('settings.mat', 'settings')

    % Stop the device
    [status1.stop] = invoke(pscope1, 'ps4000aStop');

    %% Plot Data

    % Plot data values returned from the device.
    % Calculate sampling interval (nanoseconds) and convert to milliseconds
    % Use the timeIntervalNanoSeconds output from the |ps4000aGetTimebase2()|
    % function or calculate it using the main Programmer's Guide.

    % Obtain the channel range and units
    [~, chAUnits] = invoke(pscope1, 'getChannelInputRangeAndUnits', ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_A);
    %[~, chBUnits] = invoke(pscope1, 'getChannelInputRangeAndUnits', ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_B);

    timeNs = double(timeIntervalNanoSeconds) * double(0:numSamples - 1);
    timeMs = timeNs / 1e6;

    axes1 = axes('Parent', figure);
    grid(axes1, 'on');
    hold(axes1, 'all');
    
    for i = 1:numCaptures
    
        plot3(timeNs, i * (ones(numSamples, 1)), chA(:, i));
    end

    % yyaxis right
    % plot(timeMs, chB);
    % ylabel(getVerticalAxisLabel(chBUnits));

    title(axes1, 'Rapid Block Data Acquisition - Channel A')
    xlabel(axes1, 'Time (ns)');
    ylabel(axes1, 'Capture');
    % legend('Channel A', 'Channel B');
    % grid on;

    zlabel(axes1, getVerticalAxisLabel(chAUnits));
    hold off;
    
    %% Disconnect device

    disconnect(pscope1);
    delete(pscope1);

catch ME

    msgText = getReport(ME, 'extended', 'hyperlinks', 'off');
    disp(msgText);

    if exist('pscope1','var')

        disp('Closing picoscope');
        picoscope4000a_disconnect(pscope1);
    end
    
    % if exist('chA1','var')
    % 
    %     x = 1:length(chA);
    %     figure; plot(x, chA, x, chB, x, chE);
    %     legend('Sel1', 'Cur', 'Rx1z');
    %     grid on;
    %     xlabel('Sample');
    %     ylabel('Amp(mV)');
    %     title('Error occured. Debugging signals');
    % end
end
end