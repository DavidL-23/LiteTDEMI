%When data is loaded in as a matlab file from PicoScope. 
%Tinterval = the timeing for the picoscope collected at (time for each sample)
clear; %close all;

Data=[];
Current=[];

BinsToAdd = 120;
NumberofWaves = 64;
%dirLoc = uigetdir('C:\Users\RDCRLDL9\Documents\Waveforms\');
%dirLoc = uigetdir('G:\.shortcut-targets-by-id\1kAamRkfDNNy_AXg50XcHTUD_yHhLjjBX\lithos\Michele\Saltwater_Detection_Stuff\');
dirLoc = uigetdir('E:\Waveforms\');
if dirLoc==0
    return;
end
[dirSaveLoc,dirChosen] = fileparts(dirLoc);
fNames = (dirChosen+"_");
fldtmp=fullfile(dirLoc,fNames);

%This will load all the files in the folder and put them into the
%"Data" and "Current" arrays.  Each file is tacked onto the end so that
%it is a 1 x BIG array.
for i = 1:NumberofWaves
    tmpN=int2str(1e3+i);                                %need to add 1000 to everything so that 1-9 in the count are 01-09
    filename=strcat(fldtmp,tmpN(3:end),'.mat');
    load(filename);
    N=RequestedLength; %length(A);
    Data((i-1)*N+1:i*N)=A(1:N);
    Current((i-1)*N+1:i*N)=B(1:N);
    TimeN(i)=Tstart;
    % semilogy(abs(A)); hold on;
    % semilogy(abs(B)); hold off;
end

tmpP=find(abs(Current)>1);
%tmpP=find(abs(Current)>4.5); %Misha sends a large spike to indicate the end of the transmitted pulse.  Find those spikes
itimeStart(1)=min(tmpP(1)); %find the first place where the spike is >1V
dtime=tmpP(1)+BinsToAdd;%120 is the number of data points to ignore after the spike.  Talk to Fridon about how this is calculated
icount=1;

%Finding the start time and doing a quick error check
for itime=2:length(tmpP)
    timeTmp=Tinterval*(tmpP-dtime);
    IK=min(find(timeTmp>0)); 

    if(isempty(IK)==0)
        icount=icount+1;
        itimeStart(icount)=tmpP((IK)); %This looks like the first datapoint on the indicator pulse
        dtime=tmpP((IK))+BinsToAdd; 
        %dtime(icount)=tmpP((IK))+BinsToAdd
    end
end

Signal(1:2e4)=0;%Signal will be 1:2e4 in length which equates to 1e-6 to 2e-3 seconds (i.e 0.1-2000 microseconds)
for icount=1:length(itimeStart)-5 %Skip the last 5 b/c of timing decay cut-offs
    Signal(1:2e4)=Signal(1:2e4) + Data(itimeStart(icount)+1:itimeStart(icount)+2e4)/Current(itimeStart(icount)-BinsToAdd);%Times step here again, dividing by current.
end

RawTime=1*(1:2e4)*Tinterval;
Tmin=Tinterval;
Tmax=1*2e4*Tinterval;

NtmpTime=50; %number of bins

TimeTmp=log10(Tmin):(log10(Tmax)-log10(Tmin))/NtmpTime:log10(Tmax);
for ipoint=1:size(TimeTmp,2)-1
    Npoint(ipoint,1)=max(find(log10(RawTime)<=TimeTmp(ipoint)));
    Npoint(ipoint,2)=max(find(log10(RawTime)<TimeTmp(ipoint+1)));

    SignalFinnal(ipoint)=mean(Signal(Npoint(ipoint,1):Npoint(ipoint,2)));
end


%%
prompt = "Is this background? (Y/N)";
ans = input(prompt,"s");
if ans =="Y"
    BKG=SignalFinnal;
    save(fullfile(dirSaveLoc,"Background.mat"),"BKG");
%else isempty(ans)
%    ans = 'N';
%else
%    display("Must be either 'Y' or 'N'")
else
      ans = "N";
end

if ans == "N"
    BKG = load(fullfile(dirSaveLoc,"Background.mat"));
    BKG = BKG.BKG;
    figure
    loglog(10.^TimeTmp(1:NtmpTime), abs(BKG),'--+')
    hold on
    loglog(10.^TimeTmp(1:NtmpTime), abs(SignalFinnal),'--x')
    loglog(10.^TimeTmp(1:NtmpTime), abs((SignalFinnal)-(BKG)),'-o')
    hold off
    grid on;
    legend('Bkg','Signal','Bkg Subtract')
    title('Overlayed')
end
