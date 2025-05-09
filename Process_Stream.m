clc;
clear; 
%close all;

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

% Data = (double(chA))';
% Current = (double(chB))';

Current = Current' - mean(Current);                     % Remove the DC spike
Data = Data - mean(Data);

%% Data Binning

BinsToAdd = 120;

tmpP = find(abs(Current) > 2000);
%itimeStart(1)= min(tmpP(1));                            % The first place where the space is >2V
%dtime = tmpP(1) + BinsToAdd;                            % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated                         % 120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated


% tmpP_Pos = find((Current) > 4500);
% tmpP_Neg = find((Current) < 500);
% 
% %Merge the two arrays
% tmpP = [tmpP_Pos, tmpP_Neg];
% 
% % Sort in ascending order to maintain the original order of occurrences
% tmpP = sort(tmpP)';

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

    Signal(1:ListenTimeEnd) = Signal(1:ListenTimeEnd) + Data(itimeStart(icount)+1:itimeStart(icount)+ListenTimeEnd)/...
        Current(itimeStart(icount)-BinsToAdd);          % Times step here again, dividing by current.

    %semilogx(Data(itimeStart(icount)+1:itimeStart(icount)+ListenTimeEnd));
    % semilogx(Data(itimeStart(icount)+1:itimeStart(icount))+400);
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

%% Sepearate the Positive and Negative ON Segments

if Current(itimeStart(1)) < 0
    DataStart = 0;                                      % Starts with a Negative Decay
elseif Current(itimeStart(1)) > 0
    DataStart = 1;                                      % Starts with a Positive Decay
end

itimeStart_Positive = [];
itimeStart_Negative = [];

% Separate indexes into Positive and Negative Decays
for i = 1:length(itimeStart)

    if mod(i, 2) == DataStart                           % Matches Starting Decay Type
        itimeStart_Negative = [itimeStart_Negative, itimeStart(i)];
    else
        itimeStart_Positive = [itimeStart_Positive, itimeStart(i)];
    end
end

% Inititalize Signals
Signal_Positive = zeros(1, ListenTimeEnd);
Signal_Negative = zeros(1, ListenTimeEnd);

% f_11 = figure(11);
% movegui(f_11, "northwest");
% title('Positve Decay Segments')
% xlabel('Time');
% ylabel('Magnitude (V)');
% hold on; grid on;

% Process and plot positive decays
for icount = 1:length(itimeStart_Positive)-5

    Signal_Positive(1:ListenTimeEnd) = Signal_Positive(1:ListenTimeEnd) + Data(itimeStart_Positive(icount)+1:itimeStart_Positive(icount)+ListenTimeEnd)/...
        Current(itimeStart_Positive(icount)-BinsToAdd);

    %semilogx(Data(itimeStart_Positive(icount)+1:itimeStart_Positive(icount)+ListenTimeEnd));
    % semilogx(Data(itimeStart_Positive(icount)+1:itimeStart_Positive(icount)+400));
end

% f_12 = figure(12);
% movegui(f_12, "northwest");
% title('Negative Decay Segments')
% xlabel('Time');
% ylabel('Magnitude (V)');
% hold on; grid on;

% Process and plot negative decays
for icount = 1:length(itimeStart_Negative)-5

    Signal_Negative(1:ListenTimeEnd) = Signal_Negative(1:ListenTimeEnd) + Data(itimeStart_Negative(icount)+1:itimeStart_Negative(icount)+ListenTimeEnd)/...
        Current(itimeStart_Negative(icount)-BinsToAdd);

    %semilogx(Data(itimeStart_Negative(icount)+1:itimeStart_Negative(icount)+ListenTimeEnd));
    % semilogx(Data(itimeStart_Negative(icount)+1:itimeStart_Negative(icount)+400));
end

RawTime = 1*(1:ListenTimeEnd)*timeIntervalNanoSeconds;
Tmin = 1*ListenTimeStart * timeIntervalNanoSeconds;
Tmax = 1*ListenTimeEnd*timeIntervalNanoSeconds;

SignalFinnal_Pos = zeros(1, NtmpTime);
SignalFinnal_Neg = zeros(1, NtmpTime);

TimeTmp = log10(Tmin):(log10(Tmax)-log10(Tmin))/NtmpTime:log10(Tmax);
for ipoint = 1:size(TimeTmp,2)-1
    
    Npoint(ipoint,1) = find(log10(RawTime)<=TimeTmp(ipoint), 1, 'last' );
    Npoint(ipoint,2) = find(log10(RawTime)<TimeTmp(ipoint+1), 1, 'last' );

    SignalFinnal_Pos(ipoint) = mean(Signal_Positive(Npoint(ipoint,1):Npoint(ipoint,2)));
    SignalFinnal_Neg(ipoint) = mean(Signal_Negative(Npoint(ipoint,1):Npoint(ipoint,2)));
end

%% Plot Data

prompt = "Is this background? (Y/N)";
answer = input(prompt, "s");

if answer == "Y" || answer == 'y'

    BKG = SignalFinnal;
    save(fullfile(dirSaveLoc, "Background.mat"), "BKG");
    BKG_Pos = SignalFinnal_Pos;
    save(fullfile(dirSaveLoc, "Background_Pos.mat"), "BKG_Pos");
    BKG_Neg = SignalFinnal_Neg;
    save(fullfile(dirSaveLoc, "Background_Neg.mat"), "BKG_Neg");
else

      answer = "N";
end

if answer == "N" || answer == 'n'

    BKG = load(fullfile(dirSaveLoc, "Background.mat"));
    BKG = BKG.BKG;

    BKG_Pos = load(fullfile(dirSaveLoc, "Background_Pos.mat"));
    BKG_Pos = BKG_Pos.BKG_Pos;

    BKG_Neg = load(fullfile(dirSaveLoc, "Background_Neg.mat"));
    BKG_Neg = BKG_Neg.BKG_Neg;

    figure

    loglog(10.^TimeTmp(1:NtmpTime), abs(BKG), '--+')
     hold on
    loglog(10.^TimeTmp(1:NtmpTime), abs(SignalFinnal), '--x')
    loglog(10.^TimeTmp(1:NtmpTime), abs((SignalFinnal)-(BKG)), '-o')

    legend('Bkg', 'Signal', 'Bkg Subtract')
    title('Overlayed - ', settings{1,1})
    xlabel('Frequency (Hz)')
    ylabel('Magnitude (V)')

    hold off; grid on;

    figure

    loglog(10.^TimeTmp(1:NtmpTime), abs(BKG_Pos), '--+')
     hold on
    loglog(10.^TimeTmp(1:NtmpTime), abs(SignalFinnal_Pos), '--x')
    loglog(10.^TimeTmp(1:NtmpTime), abs((SignalFinnal_Pos)-(BKG_Pos)), '-o')

    legend('Bkg', 'Signal', 'Bkg Subtract')
    title('Overlayed (Positive)- ', settings{1,1})
    xlabel('Frequency (Hz)')
    ylabel('Magnitude (V)')

    hold off; grid on;

    figure

    loglog(10.^TimeTmp(1:NtmpTime), abs(BKG_Neg), '--+')
     hold on
    loglog(10.^TimeTmp(1:NtmpTime), abs(SignalFinnal_Neg), '--x')
    loglog(10.^TimeTmp(1:NtmpTime), abs((SignalFinnal_Neg)-(BKG_Neg)), '-o')

    legend('Bkg', 'Signal', 'Bkg Subtract')
    title('Overlayed (Negative)- ', settings{1,1})
    xlabel('Frequency (Hz)')
    ylabel('Magnitude (V)')

    hold off; grid on;
end