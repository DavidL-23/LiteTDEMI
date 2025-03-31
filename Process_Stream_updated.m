clc;
clear; 
% close all;

%% Load Settings

dirLoc = uigetdir([getenv('HOMEDRIVE'), getenv('HOMEPATH'), '\Desktop\Data_Lite\']);
%settingsLoc = uigetdir('C:\Users\RDCRLDL9\Desktop\Data_Lite\');
load([dirLoc, '\settings.mat'], 'settings');
 
% Default Settings
Data = [];
Current = [];

%% Load Data

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

Current = Current' - mean(Current);                     % Remove the DC spike
Data = Data - mean(Data);

%% Data Binning
%Fridon code, but gives multiple Start times
%timeIntervalNanoSeconds = timeIntervalNanoSeconds * (1e-9);      % Convert to Nano Seconds
%itimeStart = zeros(1, 100);

% tmpP = find(abs(Current/1000) > 2);                       % Misha sends a large spike to indicate the end of the transmitted pulse.  Find those spikes
% itimeStart(1) = min(tmpP(1));                           % Find the first place where the spike is >1V
% dtime = tmpP(1) + BinsToAdd;                            % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated
% icount = 1;
% 
% for itime = 2:length(tmpP)
% 
%     timeTmp = timeIntervalNanoSeconds * (tmpP - dtime);
%     IK = find(timeTmp > 0, 1 ); 
% 
%     if(isempty(IK) == 0)
% 
%         icount = icount + 1;
%         itimeStart(icount) = tmpP((IK));                % This looks like the first datapoint on the indicator pulse
%         dtime = tmpP((IK)) + BinsToAdd; 
%         %dtime(icount) = tmpP((IK)) + BinsToAdd
%     end
% end
% 
% itimeStart = itimeStart(itimeStart > 0);

%% Data Binning
BinsToAdd = 120;
N = length(Data);
tmpP = find(abs(Current) > 2000); 
%itimeStart(1)= min(tmpP(1)); %the first place where the space is >2V
dtime = tmpP(1) + BinsToAdd;    % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated                         % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated

tol = 20000;
dx = diff(tmpP);%use this to find the difference in the tmpP, i.e how far apart each point that is greater than 2V
m = length(find(dx>200)); %define the number of clusters to use in the kmeans do this by finding all the differences that are > 300
[idx,Cent] = kmeans(tmpP,m+1); %cluster the responses that happen at the spikes

icount = 1;
for igrp = 1:length(unique(idx)) %This will iterate through the groups and select the first occurance in each group to assign to Start time
    tmpgrp = find(idx == igrp);
    itimeStart(icount) = tmpP(tmpgrp(1));
    icount = icount+1;
    clear tmpgrp;
end

itimeStart = sort(itimeStart);
%%

%PulseRate = 60; %60Hz
%PulseTime = 1/PulseRate;
%PulseLength = floor(PulseTime/timeIntervalNanoSeconds); 

%ListenTime = floor(min(xx));

ListenTimeStart = 1; %use this for binning to start binning a bit later
ListenTimeEnd = 1.33e6; %from 12.5ns to 16.6ms %This will change depending on sampling frequency!!
Signal(1:ListenTimeEnd) = 0;                                      % 

%for icount = 1:3
for icount = 1:length(itimeStart)-1                     % Skip the last 5 b/c of timing decay cut-offs
    Signal(1:ListenTimeEnd) = Signal(1:ListenTimeEnd) + Data(itimeStart(icount)+1:itimeStart(icount)+ListenTimeEnd)/Current(itimeStart(icount)-BinsToAdd); % Times step here again, dividing by current.
end
Signal=1/icount*Signal;
%%

RawTime = 1*(1:ListenTimeEnd)*timeIntervalNanoSeconds;
Tmin = 1*ListenTimeStart * timeIntervalNanoSeconds;
Tmax = 1*ListenTimeEnd*timeIntervalNanoSeconds;

NtmpTime = 50;                                          % Number of bins
Npoint = zeros(NtmpTime, 2);
SignalFinnal = zeros(1, NtmpTime);

TimeTmp = log10(Tmin):(log10(Tmax)-log10(Tmin))/NtmpTime:log10(Tmax);
%TimeTmp2 = logspace(log10(Tmin),log10(Tmax),NtmpTime);


for ipoint = 1:size(TimeTmp,2)-1

    Npoint(ipoint,1) = find(log10(RawTime)<=TimeTmp(ipoint), 1, 'last' );
    Npoint(ipoint,2) = find(log10(RawTime)<TimeTmp(ipoint+1), 1, 'last' );

    SignalFinnal(ipoint) = mean(Signal(Npoint(ipoint,1):Npoint(ipoint,2)));
end
%%
% Signal(1:ListenTime) = 0;                                      % Signal will be 1:ListenTime in length which equates to 1e-6 to 2e-3 seconds (i.e 0.1-2000 microseconds)
% 
% for icount = 1:length(itimeStart)-1                     % Skip the last 5 b/c of timing decay cut-offs
%     Signal(icount,1:ListenTime)=Signal(1:ListenTime) + Data(itimeStart(icount)+1:itimeStart(icount)+ListenTime)/Current(itimeStart(icount)-BinsToAdd);      % Times step here again, dividing by current.
% end
% 
% RawTime = 1*(1:length(chA))*timeIntervalNanoSeconds;
% Tmin = timeIntervalNanoSeconds;
% Tmax = 1*ListenTime*timeIntervalNanoSeconds;
% 
% NtmpTime = 25;                                          % Number of bins
% Npoint = zeros(NtmpTime, 2); %Start and stop times for each of the bins
% SignalFinnal = zeros(1, NtmpTime); 
% 
% %TimeTmp = log10(Tmin):(log10(Tmax)-log10(Tmin))/NtmpTime:log10(Tmax); %What's this doing here???? This gives negative values for time
% TimeTmp = logspace(log10(Tmin),log10(Tmax),NtmpTime);
% for ipoint = 1:size(TimeTmp,2)-1
%     Npoint(ipoint,1) =find(RawTime>=TimeTmp(ipoint),1,'first');
%     Npoint(ipoint,2) =find(RawTime<TimeTmp(ipoint+1),1,'first');
%     %Npoint(ipoint,1) = find(log10(RawTime)<=TimeTmp(ipoint), 1, 'last' );
%     %Npoint(ipoint,2) = find(log10(RawTime)<TimeTmp(ipoint+1), 1, 'last' );
% 
%     %SignalFinnal(ipoint) = mean(Signal(Npoint(ipoint,1):Npoint(ipoint,2)));
% end

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
    data = SignalFinnal;
    n = strcat(dirChosen,"_90cm_10x.mat");
    %save(fullfile("C:\Users\RDCRLMM8\Desktop\LiteTDEMI\Data\2025_03_14\30Bins",n),'data');

    BKG = load(fullfile(dirSaveLoc, "Background.mat"));
    BKG = BKG.BKG;

    figure

    loglog(10.^TimeTmp(1:NtmpTime), abs(BKG), '--+')
     hold on
    loglog(10.^TimeTmp(1:NtmpTime), abs(SignalFinnal), '--x')
    loglog(10.^TimeTmp(1:NtmpTime), abs((SignalFinnal)-(BKG)), '-o')

    legend('Bkg', 'Signal', 'Bkg Subtract')
    title('Overlayed - ', settings{1,1})
    xlabel('Time (s)')
    ylabel('Magnitude (V)')

    hold off
    grid on
end