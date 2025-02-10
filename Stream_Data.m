% When data is loaded in as a matlab file from PicoScope. 
% timeIntevnalNanoSeconds = The timeing for the picoscope collected at (time for each sample)

clear; 
%close all;

%% Load Settings

%settingsLoc = uigetdir('C:\Users\RDCRLDL9\Desktop\Picoscope_Collect\');
settingsLoc = uigetdir('C:\Users\RDCRLDL9\Desktop\LiteTDEMI\Data\');
load([settingsLoc, '\settings.mat'], 'settings');
 
% Default Settings
Data=[];
Current=[];
BinsToAdd = 120;

%% Load Data

% This will load all the files in the folder and put them into the
% "Data" and "Current" arrays.  Each file is tacked onto the end so that
% it is a 1 x BIG array.

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

    %TimeN(i) = Tstart;
end

Data = abs(double(chA))';
Current = abs(double(chB))';

%% Data Binning

tmpP = find(abs(Current) > 4500);                       % Misha sends a large spike to indicate the end of the transmitted pulse.  Find those spikes
itimeStart(1) = min(tmpP(1));                           % Find the first place where the spike is >1V
dtime = tmpP(1) + BinsToAdd;                            % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated
icount = 1;

% Finding the start time and doing a quick error check
%timeIntervalNanoSeconds = timeIntervalNanoSeconds * (1e-9);      % Convert to Nano Seconds
for itime = 2:length(tmpP)

    timeTmp = timeIntervalNanoSeconds * (tmpP - dtime);
    IK = min(find(timeTmp > 0)); 

    if(isempty(IK) == 0)

        icount = icount + 1;
        itimeStart(icount) = tmpP((IK));                % This looks like the first datapoint on the indicator pulse
        dtime = tmpP((IK)) + BinsToAdd; 
        %dtime(icount) = tmpP((IK)) + BinsToAdd
    end
end

Signal(1:2e4) = 0;                                      % Signal will be 1:2e4 in length which equates to 1e-6 to 2e-3 seconds (i.e 0.1-2000 microseconds)
for icount = 1:length(itimeStart)-5                     % Skip the last 5 b/c of timing decay cut-offs

    Signal(1:2e4)=Signal(1:2e4) + Data(itimeStart(icount)+1:itimeStart(icount)+2e4)/Current(itimeStart(icount)-BinsToAdd);      % Times step here again, dividing by current.
end

RawTime = 1*(1:2e4)*timeIntervalNanoSeconds;
Tmin = timeIntervalNanoSeconds;
Tmax = 1*2e4*timeIntervalNanoSeconds;

NtmpTime = 50;                                          % Number of bins

TimeTmp = log10(Tmin):(log10(Tmax)-log10(Tmin))/NtmpTime:log10(Tmax);
for ipoint = 1:size(TimeTmp,2)-1
    
    Npoint(ipoint,1) = max(find(log10(RawTime)<=TimeTmp(ipoint)));
    Npoint(ipoint,2) = max(find(log10(RawTime)<TimeTmp(ipoint+1)));

    SignalFinnal(ipoint) = mean(Signal(Npoint(ipoint,1):Npoint(ipoint,2)));
end


%% Plot Data

prompt = "Is this background? (Y/N)";
ans = input(prompt, "s");

if ans == "Y"

    BKG = SignalFinnal;
    save(fullfile(dirSaveLoc, "Background.mat"), "BKG");
else

      ans = "N";
end

if ans == "N"

    BKG = load(fullfile(dirSaveLoc, "Background.mat"));
    BKG = BKG.BKG;
    figure
    loglog(10.^TimeTmp(1:NtmpTime), abs(BKG), '--+')
    hold on
    loglog(10.^TimeTmp(1:NtmpTime), abs(SignalFinnal), '--x')
    loglog(10.^TimeTmp(1:NtmpTime), abs((SignalFinnal)-(BKG)), '-o')
    hold off
    grid on;
    legend('Bkg','Signal','Bkg Subtract')
    title('Overlayed')
end

%% Testing Code

% for i= 1:length(itimeStart) 
% 
%     xline(itimeStart(i)); 
% 
% end