clc;
clear; 
% close all;

%% Load Settings

%settingsLoc = uigetdir('C:\Users\RDCRLDL9\Desktop\Picoscope_Collect\');
settingsLoc = uigetdir('C:\Users\RDCRLDL9\Desktop\Data_Lite\');
load([settingsLoc, '\settings.mat'], 'settings');
 
% Default Settings
Data=[];
Current=[];
BinsToAdd = 120;

%% Load Data

dirLoc = uigetdir(settingsLoc);
if dirLoc == 0

    return;
end

[dirSaveLoc, dirChosen] = fileparts(dirLoc);
fNames = (dirChosen + "_");
fldtmp = fullfile(dirLoc, fNames);

result = settings(strcmp(settings.FNames, dirChosen), 2:end);
NumberofWaves = result.Count(1);

for i = 1:NumberofWaves
    
    % Load Data File
    tmpN = int2str(i);
    filename = strcat(fldtmp, tmpN, '.mat');
    load(filename);

    % Append Channels Data to Respective Arrays
    N = length(chA);
    Data((i-1)*N+1:i*N) = chA(1:N);
    Current((i-1)*N+1:i*N) = chB(1:N);
end

Data = abs(double(chA))';
Current = abs(double(chB))';

%% Data Binning

%timeIntervalNanoSeconds = timeIntervalNanoSeconds * (1e-9);      % Convert to Nano Seconds
itimeStart = zeros(1, 100);

tmpP = find(abs(Current) > 4500);                       % Misha sends a large spike to indicate the end of the transmitted pulse.  Find those spikes
itimeStart(1) = min(tmpP(1));                           % Find the first place where the spike is >1V
dtime = tmpP(1) + BinsToAdd;                            % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated
icount = 1;

for itime = 2:length(tmpP)

    timeTmp = timeIntervalNanoSeconds * (tmpP - dtime);
    IK = find(timeTmp > 0, 1 ); 

    if(isempty(IK) == 0)

        icount = icount + 1;
        itimeStart(icount) = tmpP((IK));                % This looks like the first datapoint on the indicator pulse
        dtime = tmpP((IK)) + BinsToAdd; 
        %dtime(icount) = tmpP((IK)) + BinsToAdd
    end
end

itimeStart = itimeStart(itimeStart > 0);

Signal(1:2e4) = 0;                                      % Signal will be 1:2e4 in length which equates to 1e-6 to 2e-3 seconds (i.e 0.1-2000 microseconds)
for icount = 1:length(itimeStart)-5                     % Skip the last 5 b/c of timing decay cut-offs

    Signal(1:2e4)=Signal(1:2e4) + Data(itimeStart(icount)+1:itimeStart(icount)+2e4)/Current(itimeStart(icount)-BinsToAdd);      % Times step here again, dividing by current.
end

RawTime = 1*(1:2e4)*timeIntervalNanoSeconds;
Tmin = timeIntervalNanoSeconds;
Tmax = 1*2e4*timeIntervalNanoSeconds;

NtmpTime = 50;                                          % Number of bins
Npoint = zeros(NtmpTime, 2);
SignalFinnal = zeros(1, NtmpTime);

TimeTmp = log10(Tmin):(log10(Tmax)-log10(Tmin))/NtmpTime:log10(Tmax);
for ipoint = 1:size(TimeTmp,2)-1
    
    Npoint(ipoint,1) = find(log10(RawTime)<=TimeTmp(ipoint), 1, 'last' );
    Npoint(ipoint,2) = find(log10(RawTime)<TimeTmp(ipoint+1), 1, 'last' );

    SignalFinnal(ipoint) = mean(Signal(Npoint(ipoint,1):Npoint(ipoint,2)));
end

%% Plot Data

prompt = "Is this background? (Y/N)";
answer = input(prompt, "s");

if answer == "Y" || answer == 'y'

    BKG = SignalFinnal;
    save(fullfile(dirSaveLoc, "Background.mat"), "BKG");
else

      answer = "N";
end

if answer == "N" || answer == 'n'

    BKG = load(fullfile(dirSaveLoc, "Background.mat"));
    BKG = BKG.BKG;

    figure

    loglog(10.^TimeTmp(1:NtmpTime), abs(BKG), '--+')
     hold on
    loglog(10.^TimeTmp(1:NtmpTime), abs(SignalFinnal), '--x')
    loglog(10.^TimeTmp(1:NtmpTime), abs((SignalFinnal)-(BKG)), '-o')

    legend('Bkg', 'Signal', 'Bkg Subtract')
    title('Overlayed - ', settings{1,1})
    xlabel('Frequency (Hz)')
    ylabel('Magnitude (V)')

    hold off
    grid on
end