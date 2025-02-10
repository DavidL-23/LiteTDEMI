function run_tdem_block(app)

%% Clear command window and close any figures
l   = [3 39 15];
lbl = {'Tx1 Rx1z','Tx3 Rx1z','Tx2 Rx1z'};
AUTO_TRIG_MS = 300;
TRIGLEVEL_MV = 1000;
TIMEBASE     = 7;

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
    % let the user know which picoscope is working
    
    % setup the processing
    % binner = tdembinner1(app.n_ch, app.n_tx, app.holdoff_s, app.off_time_s, app.fs, app.n_bins);

    buff_cycles = 5;
    PRETRIG1_S  = 100;
    POSTTRIG1_S = floor(app.T_s * app.fs * buff_cycles);
    T_S         = ceil(app.T_s/app.dt);             % samples per tx period
    decay_S     = ceil(T_S/4);                      % number of samples in a decay

    %% Load configuration information
    PS4000aConfig;

    %% Device connection
    % Create a device object. 
    % The serial number can be specified as a second input parameter.
    pscope1 = icdevice('picotech_ps4000a_generic.mdd', app.sn_current);

    % Connect device object to hardware.
    disp(app.sn_current);
    connect(pscope1);

    %% Set channels
    %
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
    sync_amp = 8;
    switch app.range_rx_mv
        case 10
            disp('Setting Rx Range to 10 mV');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_10MV;
        case 20
            disp('Setting Rx Range to 20 mV');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_20MV;
        case 50 
            disp('Setting Rx Range to 50 mV');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_50MV;
        case 100
            disp('Setting Rx Range to 100 mV');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_100MV;
        case 200
            disp('Setting Rx Range to 200 mV');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_200MV;
        case 500
            disp('Setting Rx Range to 500 mV');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_500MV;
        case 2000
            disp('Setting Rx Range to 2 V');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_2V;
        case 5000
            disp('Setting Rx Range to 5 V');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_5V;
        case 10000
            disp('Setting Rx Range to 10 V');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_10V;
        case 20000
            disp('Setting Rx Range to 20 V');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_20V;
        otherwise
            disp('Setting Rx Range to 1 V');
            rxV = ps4000aEnuminfo.enPS4000ARange.PS4000A_1V;
    end

    % Execute device object function(s).
    [status1.setChA] = invoke(pscope1, 'ps4000aSetChannel', 0, 1, 1, sync_amp, 0.0);
    [status1.setChB] = invoke(pscope1, 'ps4000aSetChannel', 1, 1, 1, sync_amp, 0.0);
    [status1.setChC] = invoke(pscope1, 'ps4000aSetChannel', 2, 1, 1, rxV, 0.0);
    [status1.setChD] = invoke(pscope1, 'ps4000aSetChannel', 3, 1, 1, rxV, 0.0);
    [status1.setChE] = invoke(pscope1, 'ps4000aSetChannel', 4, 1, 1, rxV, 0.0);
    [status1.setChF] = invoke(pscope1, 'ps4000aSetChannel', 5, 1, 1, rxV, 0.0);
    [status1.setChG] = invoke(pscope1, 'ps4000aSetChannel', 6, 1, 1, rxV, 0.0);
    [status1.setChH] = invoke(pscope1, 'ps4000aSetChannel', 7, 1, 1, rxV, 0.0);

    [chAInputRange, chAUnits] = invoke(pscope1, ...
        'getChannelInputRangeAndUnits', ...
        ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_A);
    [chBInputRange, chBUnits] = invoke(pscope1, ...
        'getChannelInputRangeAndUnits', ...
        ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_B);
    [chCInputRange, chCUnits] = invoke(pscope1, ...
        'getChannelInputRangeAndUnits', ...
        ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_C);
    [chDInputRange, chDUnits] = invoke(pscope1, ...
        'getChannelInputRangeAndUnits', ...
        ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_D);
    [chEInputRange, chEUnits] = invoke(pscope1, ...
        'getChannelInputRangeAndUnits', ...
        ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_E);
    [chFInputRange, chFUnits] = invoke(pscope1, ...
        'getChannelInputRangeAndUnits', ...
        ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_F);
    [chGInputRange, chGUnits] = invoke(pscope1, ...
        'getChannelInputRangeAndUnits', ...
        ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_G);
    [chHInputRange, chHUnits] = invoke(pscope1, ...
        'getChannelInputRangeAndUnits', ...
        ps4000aEnuminfo.enPS4000AChannel.PS4000A_CHANNEL_H);

    %% Verify timebase index and maximum number of samples
    %
    % Driver default timebase index used - use |ps4000aGetTimebase2()| to query the
    % driver as to suitability of using a particular timebase index and the
    % maximum number of samples available in the segment selected (the buffer
    % memory has not been segmented in this example) then set the |timebase|
    % property if required.
    %
    % To use the fastest sampling interval possible, set one analog channel
    % and turn off all other channels.
    %
    % Use a while loop to query the function until the status indicates that a
    % valid timebase index has been selected. In this example, the timebase 
    % index of 79 is valid. 

    % Initial call to ps4000aGetTimebase2() with parameters:
    % timebase      : 79
    % segment index : 0
    status1.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
    timebaseIndex = TIMEBASE;
    while(status1.getTimebase2 == PicoStatus.PICO_INVALID_TIMEBASE)
        [status1.getTimebase2, timeIntervalNanoSeconds, maxSamples] = invoke(pscope1,...
            'ps4000aGetTimebase2', timebaseIndex, 0);
        if (status1.getTimebase2 == PicoStatus.PICO_OK)
            break;
        else
            timebaseIndex = timebaseIndex + 1;
        end
    end

    fprintf('Timebase index: %d\n', timebaseIndex);
    set(pscope1, 'timebase', timebaseIndex);

    %% Set advanced trigger with pulse width qualifier

    % Trigger properties and functions are located in the Instrument
    % Driver's Trigger group.
    trig1 = get(pscope1, 'Trigger');
    trig1 = trig1(1);

    % Set the |autoTriggerMs| property in order to automatically trigger the
    % oscilloscope after 1 second if a trigger event has not occurred. Set to 0
    % to wait indefinitely for a trigger event.

    set(trig1, 'autoTriggerMs', AUTO_TRIG_MS);F

    % Trigger Channel Properties:
    % ---------------------------
    % Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
    % Threshold   : 1000 mV on device 1, 500 mV on device 2
    % Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)
    [status1.setSimpleTrigger] = invoke(trig1, 'setSimpleTrigger', 0, TRIGLEVEL_MV, 2);

    %% Set block parameters and capture data
    % Capture a block of data and retrieve data values for Channel A.

    % Block data acquisition properties and functions are located in the 
    % Instrument Driver's Block group.

    % % setup a button to stop data logging
    % [stopFig.h, stopFig.h] = stopButton(); 
    % flag = 1; % Use flag variable to indicate if stop button has been clicked (0)
    % setappdata(gcf, 'run', flag);

    % loop through the data collection

        block1 = get(pscope1, 'Block');
        block1 = block1(1);

        % Set pre-trigger and post-trigger samples as required.F
        set(pscope1, 'numPreTriggerSamples', PRETRIG1_S);
        set(pscope1, 'numPostTriggerSamples', POSTTRIG1_S);

        %%
        % This example uses the _runBlock_ function in order to collect a block of
        % data - if other code needs to be executed while waiting for the device to
        % indicate that it is ready, use the |ps4000aRunBlock()| function and poll
        % the |ps4000aIsReady()| function.

        % Capture a block of data:
        %
        % segment index: 0 (The buffer memory is not segmented in this example)
    
    while app.connected
        tL = javaMethod('currentTimeMillis','java.lang.System');% loop timer
        [status1.runBlock] = invoke(block1, 'runBlock', 0);
        [numSamples,~,chA,chB,chC,chD,chE,chF,chG,chH] = invoke(...
            block1, 'getBlockData', 0, 0, 1, 0);

        tB = javaMethod('currentTimeMillis','java.lang.System');% loop timer
        app.connected = false;
        save(app.fileout,'ch*','timeIntervalNanoSeconds','numSamples');

        pause(.09);
    end % end while loop

    %% Stop the device
    [status1.stop] = invoke(pscope1, 'ps4000aStop');

    %% Disconnect device
    % Disconnect device object from hardware.
    disconnect(pscope1);
    delete(pscope1);F
    x = 1:numSamples;
    figure;
    plot(x,chA,'.',x,chB,'.',x,chE,'.',x,chG,'.');
    legend('CH A (tx sel)','CH B (curr)','CH E (z)','CH G (z)');
    grid on;
catch ME
    msgText = getReport(ME,'extended','hyperlinks','off');
    disp(msgText);% display error message
    if exist('pscope1','var')
        disp('Closing picoscope');
        picoscope4000a_disconnect(pscope1);
    end
    
    if exist('chA1','var')
        x = 1:length(chA);
        figure; plot(x,chA,x,chB,x,chE);
        legend('Sel1','Cur','Rx1z');
        grid on;
        xlabel('Sample');
        ylabel('Amp(mV)');
        title('Error occured. Debugging signals');
    end
end

end