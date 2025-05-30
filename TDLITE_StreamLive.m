function TDLITE_StreamLive(app)

%% Clear command window and close any figures

sampleSize = 100e6;
bufferSize = 50e6;
timeIntervalNanoSeconds = 12.5e-9;
sampleRate = 1/timeIntervalNanoSeconds;

if nargin == 0
    app.sn_current = '';
    app.n_ch = 6;   
    app.n_tx = 4;
    app.holdoff_s = 100e-6;
    app.off_time_s = 20e-3;
    app.fs = 10e6;
    app.n_bins = 30;
    app.bkg_stack = 10;
    app.T_s = 33.33e-3;
    app.dt = 1/app.fs;
    app.connected = true;
    app.fileout = 'data.mat';
end

try 
    %% Load configuration information
    
    % % Setup paths and also load struct and enumeration information. Enumeration
    % % values are required for certain function calls.
    % [~, ps4000aEnuminfo] = ps4000aSetConfig(); % DO NOT EDIT THIS LINE.
    PS4000aConfig;

    %% Parameter definitions

    % Define any parameters that might be required throughout the script.
    
    channelA = ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_A;
    channelB = ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_B;
    % channelC = ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_C;
    % channelD = ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_D;
    % channelE = ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_E;
    % channelF = ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_F;
    % channelG = ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_G;
    % channelH = ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_G;
    
    %% Device connection

    % Check if an Instrument session using the device object 'pscope1'
    % is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
    % if (exist('pscope1', 'var') && pscope1.isvalid && strcmp(pscope1.status, 'open'))
    % 
    %     openDevice = questionDialog(['Device object pscope1 has an open connection. ' ...
    %         'Do you wish to close the connection and continue?'], ...
    %         'Device Object Connection Open');
    %     if (openDevice == PicoConstants.TRUE)
    % 
    %         % Close connection to device
    %         disconnect(pscope1);
    %         delete(pscope1);  
    %     else
    % 
    %         % Exit script if User 
    %         return;        
    %     end  
    % end

    % Create a device object. 
    % The serial number can be specified as a second input parameter.
    pscope1 = icdevice('picotech_ps4000a_generic.mdd', '');
    
    % Connect device object to hardware.
    connect(pscope1);

    %% Display unit information

    [~, unitInfo] = invoke(pscope1, 'getUnitInfo');
    
    disp('Device information:-')
    disp(unitInfo);
    
    %% Channel Setup
    
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

    % Ranges: 0 -> 10mV,  1 -> 20mV,  2 -> 50mV
    % Ranges: 3 -> 100mV, 4 -> 200mV, 5 -> 500mV
    % Ranges: 6 -> 1V,    7 -> 2V,    8 -> 5V
    % Ranges: 9 -> 10V,  10 -> 20V,  11 -> 50V
   
    % Execute device object function(s).
    [status1.setChA] = invoke(pscope1, 'ps4000aSetChannel', 0, 1, 1, 10, 0.0);
    [status1.setChB] = invoke(pscope1, 'ps4000aSetChannel', 1, 1, 1, 8, 0.0);
    [status1.setChC] = invoke(pscope1, 'ps4000aSetChannel', 2, 0, 1, 8, 0.0);
    [status1.setChD] = invoke(pscope1, 'ps4000aSetChannel', 3, 0, 1, 8, 0.0);
    [status1.setChE] = invoke(pscope1, 'ps4000aSetChannel', 4, 0, 1, 8, 0.0);
    [status1.setChF] = invoke(pscope1, 'ps4000aSetChannel', 5, 0, 1, 8, 0.0);
    [status1.setChG] = invoke(pscope1, 'ps4000aSetChannel', 6, 0, 1, 8, 0.0);
    [status1.setChH] = invoke(pscope1, 'ps4000aSetChannel', 7, 0, 1, 8, 0.0);

    % Channel A
    channelSettings(1).enabled          = PicoConstants.TRUE;
    channelSettings(1).coupling         = ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
    channelSettings(1).range            = ps4000aEnuminfo.enPS4000ARange.PS4000A_20V;
    channelSettings(1).analogueOffset   = 0.0;
    
    % Channel B
    channelSettings(2).enabled          = PicoConstants.TRUE;
    channelSettings(2).coupling         = ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
    channelSettings(2).range            = ps4000aEnuminfo.enPS4000ARange.PS4000A_5V;
    channelSettings(2).analogueOffset   = 0.0;
    
    if (pscope1.channelCount == PicoConstants.QUAD_SCOPE || ...
            pscope1.channelCount == PicoConstants.OCTO_SCOPE)
    
        % Channel C
        channelSettings(3).enabled          = PicoConstants.FALSE;
        channelSettings(3).coupling         = ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
        channelSettings(3).range            = ps4000aEnuminfo.enPS4000ARange.PS4000A_5V;
        channelSettings(3).analogueOffset   = 0.0;
    
        % Channel D
        channelSettings(4).enabled          = PicoConstants.FALSE;
        channelSettings(4).coupling         = ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
        channelSettings(4).range            = ps4000aEnuminfo.enPS4000ARange.PS4000A_5V;
        channelSettings(4).analogueOffset   = 0.0;
    end
    
    % PicoScope 4824
    if (pscope1.channelCount == PicoConstants.OCTO_SCOPE)
        
        % Channel E
        channelSettings(5).enabled          = PicoConstants.FALSE;
        channelSettings(5).coupling         = ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
        channelSettings(5).range            = ps4000aEnuminfo.enPS4000ARange.PS4000A_2V;
        channelSettings(5).analogueOffset   = 0.0;
    
        % Channel F
        channelSettings(6).enabled          = PicoConstants.FALSE;
        channelSettings(6).coupling         = ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
        channelSettings(6).range            = ps4000aEnuminfo.enPS4000ARange.PS4000A_2V;
        channelSettings(6).analogueOffset   = 0.0;
    
        % Channel G
        channelSettings(7).enabled          = PicoConstants.FALSE;
        channelSettings(7).coupling         = ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
        channelSettings(7).range            = ps4000aEnuminfo.enPS4000ARange.PS4000A_2V;
        channelSettings(7).analogueOffset   = 0.0;
    
        % Channel H
        channelSettings(8).enabled          = PicoConstants.FALSE;
        channelSettings(8).coupling         = ps4000aEnuminfo.enPS4000ACoupling.PS4000A_DC;
        channelSettings(8).range            = ps4000aEnuminfo.enPS4000ARange.PS4000A_2V;
        channelSettings(8).analogueOffset   = 0.0;
    end

    % Obtain the number of analog channels on the device from the driver
    numChannels = get(pscope1, 'channelCount');
    
    for ch = 1:numChannels
       
        status1.setChannelStatus(ch) = invoke(pscope1, 'ps4000aSetChannel', ...
            (ch - 1), channelSettings(ch).enabled, ...
            channelSettings(ch).coupling, channelSettings(ch).range, ...
            channelSettings(ch).analogueOffset);
    end

    % Obtain the range and units for each enabled channel. For the PicoScope
    % 4824, this will be in millivolts.
    [chAInputRange, chAUnits] = invoke(pscope1, 'getChannelInputRangeAndUnits', ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_A);
    [chBInputRange, ~] = invoke(pscope1, 'getChannelInputRangeAndUnits', ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_B);
    %[chCInputRange, ~] = invoke(pscope1, 'getChannelInputRangeAndUnits', ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_C);
    %[chDInputRange, ~] = invoke(pscope1, 'getChannelInputRangeAndUnits', ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_D);
    
    % Obtain the maximum Analog Digital Converter Count value from the driver
    % - this is used for scaling values returned from the driver when data is
    % collected.
    maxADCCount = double(get(pscope1, 'maxADCValue'));

    %% Set data buffers
        
    % Data buffers for Channel A and B - buffers should be set with the
    % (lib)ps400a shared library, and these *MUST* be passed with application
    % buffers to the wrapper shared library. This will ensure that data is
    % correctly copied from the shared library buffers for later processing.
    
    overviewBufferSize  = bufferSize * 2; % Size of the buffer(s) to collect data from the driver's buffer(s).
    segmentIndex        = 0;   
    ratioMode           = ps4000aEnuminfo.enPS4000ARatioMode.PS4000A_RATIO_MODE_NONE;

    % Buffers to be passed to the driver
    pDriverBufferChA = libpointer('int16Ptr', zeros(overviewBufferSize, 1, 'int16'));
    pDriverBufferChB = libpointer('int16Ptr', zeros(overviewBufferSize, 1, 'int16'));
    %pDriverBufferChC = libpointer('int16Ptr', zeros(overviewBufferSize, 1, 'int16'));
    %pDriverBufferChD = libpointer('int16Ptr', zeros(overviewBufferSize, 1, 'int16'));
    
    status1.setDataBufferChA = invoke(pscope1, 'ps4000aSetDataBuffer', ...
        channelA, pDriverBufferChA, overviewBufferSize, segmentIndex, ratioMode);

    status1.setDataBufferChB = invoke(pscope1, 'ps4000aSetDataBuffer', ...
        channelB, pDriverBufferChB, overviewBufferSize, segmentIndex, ratioMode);
    
    %status1.setDataBufferChC = invoke(pscope1, 'ps4000aSetDataBuffer', ...
    %    channelC, pDriverBufferChC, overviewBufferSize, segmentIndex, ratioMode);
    
    %status1.setDataBufferChD = invoke(pscope1, 'ps4000aSetDataBuffer', ...
    %    channelD, pDriverBufferChD, overviewBufferSize, segmentIndex, ratioMode);
    
    % Application Buffers - these are for temporarily copying data from the driver.
    pAppBufferChA = libpointer('int16Ptr', zeros(overviewBufferSize, 1));
    pAppBufferChB = libpointer('int16Ptr', zeros(overviewBufferSize, 1));
    %pAppBufferChC = libpointer('int16Ptr', zeros(overviewBufferSize, 1));
    %pAppBufferChD = libpointer('int16Ptr', zeros(overviewBufferSize, 1));
    
    % Streaming properties and functions are located in the Instrument
    % Driver's Streaming group.
    streamingGroupObj = get(pscope1, 'Streaming');
    streamingGroupObj = streamingGroupObj(1);
    
    % Register application buffer and driver buffers (with the wrapper driver).
    status1.setAppAndDriverBuffersA = invoke(streamingGroupObj, 'setAppAndDriverBuffers', channelA, ...
        pAppBufferChA, pDriverBufferChA, overviewBufferSize);

    status1.setAppAndDriverBuffersB = invoke(streamingGroupObj, 'setAppAndDriverBuffers', channelB, ...
        pAppBufferChB, pDriverBufferChB, overviewBufferSize);
    
    % status1.setAppAndDriverBuffersC = invoke(streamingGroupObj, 'setAppAndDriverBuffers', channelC, ...
    %     pAppBufferChC, pDriverBufferChC, overviewBufferSize);
    % 
    % status1.setAppAndDriverBuffersD = invoke(streamingGroupObj, 'setAppAndDriverBuffers', channelD, ...
    %     pAppBufferChD, pDriverBufferChD, overviewBufferSize);
        
    %% Start streaming and collect data
    while true
        
        % Use default value for streaming interval which is 1e-6 for 1 MS/s.
        % Collect data for 1 second with auto stop. The maximum array size will
        % depend on the PC's resources. For further information, type |memory| in
        % the MATLAB Command Window and press Enter.
        %
        % To change the sample interval set the |streamingInterval| property of the
        % |Streaming| group object. The call to |ps4000aRunStreaming()| will output the actual
        % sampling interval used by the driver.
        
        % For 200 kS/s, specify 5 us
        % set(streamingGroupObj, 'streamingInterval', 5e-6);
        % For 10 MS/s, specify 100 ns
        set(streamingGroupObj, 'streamingInterval', timeIntervalNanoSeconds);
        
        % Set the number of pre- and post-trigger samples
        % If no trigger is set 'numPreTriggerSamples' is ignored
        set(pscope1, 'numPreTriggerSamples', 0);
        set(pscope1, 'numPostTriggerSamples', sampleSize);
        
        % The autoStop parameter can be set to false (0).
        %set(streamingGroupObj, 'autoStop', PicoConstants.FALSE);
    
        % Set other streaming parameters
        downSampleRatio     = 1;
        downSampleRatioMode = ps4000aEnuminfo.enPS4000ARatioMode.PS4000A_RATIO_MODE_NONE;
        
        % Defined buffers to store data collected from the channels.
        % If capturing data without using the autoStop flag, or if using a trigger 
        % with the autoStop flag, allocate sufficient space (1.5 times the size is 
        % shown below) to allow for pre-trigger data. Pre-allocating the array is 
        % more efficient than using vertcat to combine data.
        maxSamples = get(pscope1, 'numPreTriggerSamples') + ...
            get(pscope1, 'numPostTriggerSamples');
        
        % Take into account the downsampling ratio mode - required if collecting
        % data without a trigger and using the autoStop flag. 
        % finalBufferLength = round(1.5 * maxSamples / downSampleRatio);   
        pBufferChAFinal = libpointer('int16Ptr', zeros(maxSamples, 1, 'int16'));
        pBufferChBFinal = libpointer('int16Ptr', zeros(maxSamples, 1, 'int16'));
        % pBufferChCFinal = libpointer('int16Ptr', zeros(maxSamples, 1, 'int16'));
        % pBufferChDFinal = libpointer('int16Ptr', zeros(maxSamples, 1, 'int16'));
        
        % Prompt User to indicate if they wish to plot live streaming data.
        plotLiveData = questionDialog('Plot live streaming data?', 'Streaming Data Plot');
        if (plotLiveData == PicoConstants.TRUE)

            disp('Live streaming data collection with second plot on completion.');  
        else

            disp('Streaming data plot on completion.');      
        end
        
        % Start streaming data collection.
        [status1.runStreaming, actualSampleInterval, sampleIntervalTimeUnitsStr] = ...
            invoke(streamingGroupObj, 'ps4000aRunStreaming', downSampleRatio, ...
            downSampleRatioMode, overviewBufferSize);
            
        disp('Streaming data collection...');
        fprintf('Click the STOP button to stop capture or wait for auto stop if enabled.\n\n') 
        
        % Variables to be used when collecting the data
        isAutoStopSet       = PicoConstants.FALSE;
        %newSamples          = 0; % Number of new samples returned from the driver.
        %previousTotal       = 0; % The previous total number of samples.
        totalSamples        = 0; % Total number of samples captured by the device.
        %startIndex          = 0; % Start index of data in the buffer returned (zero-based).
        hasTriggered        = 0; % To indicate if trigger event has occurred.
        triggeredAtIndex    = 0; % The index in the overall buffer where the trigger occurred (zero-based).
        
        status1.getStreamingLatestValues = PicoStatus.PICO_OK; % OK
        
        % Display a 'Stop' button.
        [stopFig.h, stopFig.h] = stopButton();             
                     
        flag = 1; % Use flag variable to indicate if the stop button has been clicked (0).
        setappdata(gcf, 'run', flag);
        
        % Plot Properties - these are for displaying data as it is collected. In
        % this example, data is displayed in millivolts. For other probes,
        % including when using PicoConnect 442 or current probes with the PicoScope
        % 4444, use the appropriate units for the vertical axes.
        if (plotLiveData == PicoConstants.TRUE)

            % Plot on a single figure 
            figure1 = figure('Name','PicoScope 4000 Series (A API) Example - Streaming Mode Capture', ...
                 'NumberTitle','off');

             axes1 = axes('Parent', figure1);

            % Estimate x-axis limit to try and avoid using too much CPU resources
            % when drawing - use max voltage range selected if plotting multiple
            % channels on the same graph.

            xlim(axes1, [0 (actualSampleInterval * maxSamples)]);

            yRange = max(chAInputRange, chBInputRange);
            ylim(axes1,[(-1 * yRange) yRange]);

            hold(axes1,'on');
            grid(axes1, 'on');

            title(axes1, 'Live Streaming Data Capture');
            xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
            xlabel(axes1, xLabelStr);
            ylabel(axes1, getVerticalAxisLabel(chAUnits));
        end
        
        % Collect samples as long as the autoStop flag has not been set or the call
        % to getStreamingLatestValues does not return an error code (check for STOP
        % button push inside loop).
        while (isAutoStopSet == PicoConstants.FALSE && status1.getStreamingLatestValues == PicoStatus.PICO_OK)
            
            ready = PicoConstants.FALSE;
           
            while (ready == PicoConstants.FALSE)
        
               status1.getStreamingLatestValues = invoke(streamingGroupObj, 'getStreamingLatestValues');
               ready = invoke(streamingGroupObj, 'isReady');
        
               % Give option to abort from here
               flag = getappdata(gcf, 'run');
               drawnow;
        
               if (flag == 0)
        
                    disp('STOP button clicked - aborting data collection.')
                    break;
               end
        
               % if (plotLiveData == PicoConstants.TRUE)
               % 
               %      drawnow;
               % end
            end
            
            % Check for new data values
            [newSamples, startIndex] = invoke(streamingGroupObj, 'availableData');
        
            if (newSamples > 0)
                
                % Check if the scope has triggered
                [triggered, triggeredAt] = invoke(streamingGroupObj, 'isTriggerReady');
        
                if (triggered == PicoConstants.TRUE)
        
                    % Adjust trigger position as MATLAB does not use zero-based
                    % indexing.
                    bufferTriggerPosition = triggeredAt + 1;
                    
                    fprintf('Triggered - index in buffer: %d\n', bufferTriggerPosition);
        
                    hasTriggered = triggered;
        
                    % Set the total number of samples at which the device
                    % triggered.
                    triggeredAtIndex = totalSamples + bufferTriggerPosition;
                end
        
                previousTotal = totalSamples;
                totalSamples  = totalSamples + newSamples;
        
                % Printing to console can slow down acquisition - use for
                % demonstration.
                fprintf('Collected %d samples, startIndex: %d total: %d.\n', newSamples, startIndex, totalSamples);
                
                % Position indices of data in the buffer(s).
                firstValuePosn = startIndex + 1;
                lastValuePosn = startIndex + newSamples;
                
                % Convert data values from the application buffer(s) - in this
                % example
                bufferChAmV = adc2mv(pAppBufferChA.Value(firstValuePosn:lastValuePosn), chAInputRange, maxADCCount);
                bufferChBmV = adc2mv(pAppBufferChB.Value(firstValuePosn:lastValuePosn), chBInputRange, maxADCCount);
                % bufferChCmV = adc2mv(pAppBufferChC.Value(firstValuePosn:lastValuePosn), chCInputRange, maxADCCount);
                % bufferChDmV = adc2mv(pAppBufferChD.Value(firstValuePosn:lastValuePosn), chDInputRange, maxADCCount);
        
                % Process collected data further if required - this example plots
                % the data if the User has selected 'Yes' at the prompt.
                
                % Copy data into the final buffer(s).
                pBufferChAFinal.Value(previousTotal + 1:totalSamples) = bufferChAmV;
                pBufferChBFinal.Value(previousTotal + 1:totalSamples) = bufferChBmV;
                % pBufferChCFinal.Value(previousTotal + 1:totalSamples) = bufferChCmV;
                % pBufferChDFinal.Value(previousTotal + 1:totalSamples) = bufferChDmV;
                
                % if (plotLiveData == PicoConstants.TRUE)
                % 
                %     % Time axis
                %     % Multiply by ratio mode as samples get reduced.
                %     time = (double(actualSampleInterval) * double(downSampleRatio)) * (previousTotal:(totalSamples - 1));
                % 
                %     plot(time, bufferChAmV, time, bufferChBmV);
                % end
        
                % Clear variables.
                clear bufferChAmV;
                clear bufferChBmV;
                clear bufferChCmV;
                clear bufferChDmV;
                clear firstValuePosn;
                clear lastValuePosn;
                clear startIndex;
                clear triggered;
                clear triggerAt;
            end
           
            % Check if auto stop has occurred.
            isAutoStopSet = invoke(streamingGroupObj, 'autoStopped');
        
            if (isAutoStopSet == PicoConstants.TRUE)
        
               disp('AutoStop: TRUE - exiting loop.');
               break;
            end
           
            % Check if 'STOP' button pressed.
            flag = getappdata(gcf, 'run');
            drawnow;
        
            if (flag == 0)
        
                disp('STOP button clicked - aborting data collection.')
                break;
            end
        end
        
        % % Close the STOP button window
        if (exist('stopFig', 'var'))
            
            close('Stop Button');
            clear stopFig;     
        end
        
        if (plotLiveData == PicoConstants.TRUE)

            drawnow;   
        end
        if (hasTriggered == PicoConstants.TRUE)

            fprintf('Triggered at overall index: %d\n', triggeredAtIndex); 
        end
        if (plotLiveData == PicoConstants.TRUE)

            % Take hold off the current figure
            hold off;
            movegui(figure1, 'west');
        end
        
        fprintf('\n');
        
        % % Stop the device
        status1.stop = invoke(pscope1, 'ps4000aStop');
    
        % % Find the number of samples
        %[status1.noOfStreamingValues, numStreamingValues] = invoke(streamingGroupObj, 'ps4000aNoOfStreamingValues');
        %fprintf('Number of samples available from the driver: %u.\n\n', numStreamingValues);
        
        % % Process data
        if (totalSamples < maxSamples)
            
            pBufferChAFinal.Value(totalSamples + 1:end) = [];
            pBufferChBFinal.Value(totalSamples + 1:end) = [];
            % pBufferChCFinal.Value(totalSamples + 1:end) = [];
            % pBufferChDFinal.Value(totalSamples + 1:end) = [];
        end

        chA = pBufferChAFinal.Value();
        chB = pBufferChBFinal.Value();
        % chC = pBufferChCFinal.Value();
        % chD = pBufferChDFinal.Value();
    
        % % Save Data
        prompt = {'Enter Datashot Type:'};
        dlgtitle = 'Input';
        fieldsize = [1 45];
        definput = {'Bkg'};
        answer = inputdlg(prompt, dlgtitle, fieldsize, definput);

        % % Check if 'Data_Lite' folder is already created. If not, create 'Data_Lite' folder
        if not(isfolder([getenv('HOMEDRIVE'), getenv('HOMEPATH'), '\Desktop\Data_Lite']))
            mkdir([getenv('HOMEDRIVE'), getenv('HOMEPATH'), '\Desktop\Data_Lite'])
        end
        
        % % Saves the location for where 'Data' will be saved to.
        dataLoc = ([getenv('HOMEDRIVE'), getenv('HOMEPATH'), '\Desktop\Data_Lite']);

        currFolder = [dataLoc, '\', answer{1}];
        mkdir(currFolder)

        FNames = answer{1};
        Count = 1;
        
        app.fileout = [currFolder, '\', answer{1}, '_', num2str(Count) , '.mat'];
        save(app.fileout, 'chA', 'chB', 'timeIntervalNanoSeconds', 'sampleRate');
    
        settings = table({FNames}, Count, 'VariableNames', {'FNames', 'Count'});
        save([currFolder, '\settings.mat'], 'settings')

        % % Process Data
        Process_StreamLive({FNames})

        % %  Continue Collecting Data?
        prompt = "Continue Collecting Data? (Y/N)";
        answer = input(prompt, "s");

        if answer == "N" || answer == "n"

            break;
        elseif answer == "Y" || answer == "y"
        
        end
    end
    
    %% Disconnect device

    % Disconnect device object from hardware.
    disconnect(pscope1);
    delete(pscope1);

catch ME

    msgText = getReport(ME, 'extended', 'hyperlinks', 'off');
    disp(msgText);

    if exist('pscope1','var')

        disp('Closing picoscope');
        picoscope4000a_disconnect(pscope1);
    end
end
end