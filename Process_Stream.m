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

BinsToAdd = 120;

tmpP = find(abs(Current) > 2000); 
%itimeStart(1)= min(tmpP(1));                            % The first place where the space is >2V
dtime = tmpP(1) + BinsToAdd;                            % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated                         % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated

tol = 20000;
dx = diff(tmpP);                                        % Use this to find the difference in the tmpP, i.e how far apart each point that is greater than 2V
m = length(find(dx>200));                               % Define the number of clusters to use in the kmeans do this by finding all the differences that are > 300
[idx,Cent] = kmeans(tmpP,m+1);                          % Cluster the responses that happen at the spikes

icount = 1;
for igrp = 1:length(unique(idx))                        % This will iterate through the groups and select the first occurance in each group to assign to Start time
    
    tmpgrp = find(idx == igrp);
    itimeStart(icount) = tmpP(tmpgrp(1));
    icount = icount + 1;

    clear tmpgrp;
end

itimeStart = sort(itimeStart);

%%

ListenTimeStart = 1;                                    % Use this for binning to start binning a bit later
ListenTimeEnd = 1.33e6;                                 % From 12.5ns to 16.6ms %This will change depending on sampling frequency!!
Signal(1:ListenTimeEnd) = 0;

% f_10 = figure(10);
% movegui(f_10, "northwest");
% xlabel('Time');
% ylabel('Magnitude (V)');
% hold on
% grid on

for icount = 1:length(itimeStart)-5                     % Skip the last 5 b/c of timing decay cut-offs

    Signal(1:ListenTimeEnd)=Signal(1:ListenTimeEnd) + Data(itimeStart(icount)+1:itimeStart(icount)+ListenTimeEnd)/...
        Current(itimeStart(icount)-BinsToAdd);          % Times step here again, dividing by current.

    %semilogx(Data(itimeStart(icount)+1:itimeStart(icount)+ListenTimeEnd));
end

%%

RawTime = 1*(1:ListenTimeEnd)*timeIntervalNanoSeconds;
Tmin = 1*ListenTimeStart * timeIntervalNanoSeconds;
Tmax = 1*ListenTimeEnd*timeIntervalNanoSeconds;

NtmpTime = 30;
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