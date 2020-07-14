clc;
clear;
close all;
%% Groundwater level estimation,using Wavelet-ANFIS model. Mohammad Zare 12.08.2015
Model{1}='using groundwater data';
Model{2}='using rainfall and groundwater data';
AN=questdlg('slect inputs','data',Model{1},Model{2},Model{2});
pause(0.1);

switch AN
    case Model{1}

g=xlsread('fdata','uh');
x=g';
p=xlsread('fdata','p'); % just for line 241 (it is not important)
y=p'; % just for line 241 (it is not important)
nLevel=2;
wave{1}='haar';
wave{2}='db4';
wave{3}='sym4';
wname=questdlg('slect wave type','type',wave{1},wave{2},wave{3},wave{3});
pause(0.1);
[a, d]=GetDWT(x,nLevel,wname);
nx=numel(x);
Delays=1:3;
MaxDelay=max(Delays);
Range=(MaxDelay+1):nx;
Inputs=[];
c=0;
for i=1:numel(Delays)
   
    for k=1:nLevel
        c=c+1;
        Inputs(c,:)=a{k}(Range-Delays(i)); %#ok
        c=c+1;
        Inputs(c,:)=d{k}(Range-Delays(i)); %#ok
    end
end


    case Model{2}
g=xlsread('fdata','uh');
x=g';
nLevel=2;
wave{1}='haar';
wave{2}='db4';
wave{3}='sym4';
wname=questdlg('slect wave type','type',wave{1},wave{2},wave{3},wave{3});
pause(0.1);
[a, d]=GetDWT(x,nLevel,wname);
nx=numel(x);
Delays=1:3;
MaxDelay=max(Delays);
Range=(MaxDelay+1):nx;
Inputsg=[];
c=0;
for i=1:numel(Delays)
    %Inputs(i,:)=x(Range-Delays(i));
    
    for k=1:nLevel
        c=c+1;
        Inputsg(c,:)=a{k}(Range-Delays(i)); %#ok
        c=c+1;
        Inputsg(c,:)=d{k}(Range-Delays(i)); %#ok
    end
end

p=xlsread('fdata','p');


y=p';
nLevel=2;
[a, d]=GetDWT(y,nLevel,wname);
ny=numel(y);
Delaysp=1:3;
MaxDelayp=max(Delaysp);
Rangep=(MaxDelayp+1):ny;
Inputsp=[];
c=0;
for i=1:numel(Delaysp)
    %Inputs(i,:)=x(Range-Delays(i));
    
    for k=1:nLevel
        c=c+1;
        Inputsp(c,:)=a{k}(Rangep-Delaysp(i)); %#ok
        c=c+1;
        Inputsp(c,:)=d{k}(Rangep-Delaysp(i)); %#ok
    end
end
Inputs=[Inputsg;Inputsp];
end
Targets=x(Range);
% tr=kk(Range);
nData=numel(Targets);
pTrain=0.7;
nTrainData=round(pTrain*nData);
TrainInputs=(Inputs(:,1:nTrainData))';
TrainTargets=(Targets(:,1:nTrainData))';
pTest=1-pTrain;
nTestData=nData-nTrainData;
TestInputs=(Inputs(:,nTrainData+1:end))';
TestTargets=(Targets(:,nTrainData+1:end))';
pause(0.1);

%% Design ANFIS

        Prompt={'Number for Clusters:',...
                'Partition Matrix Exponent:',...
                'Maximum Number of Iterations:',...
                'Minimum Improvemnet:'};
        Title='Enter genfis3 parameters';
        DefaultValues={'2','2','1000','1e-8'};
        
        PARAMS=inputdlg(Prompt,Title,1,DefaultValues);
        pause(0.1);

        nCluster=str2num(PARAMS{1}); %#ok
        Exponent=str2num(PARAMS{2}); %#ok
        MaxIt=str2num(PARAMS{3}); %#ok
        MinImprovment=str2num(PARAMS{4}); %#ok
        DisplayInfo=1;
        FCMOptions=[Exponent MaxIt MinImprovment DisplayInfo];
        
        fis=genfis3(TrainInputs,TrainTargets,'sugeno',nCluster,FCMOptions);

Prompt={'Maximum Number of Epochs:',...
        'Error Goal:',...
        'Initial Step Size:',...
        'Step Size Decrease Rate:',...
        'Step Size Increase Rate:'};
Title='Enter genfis parameters';
DefaultValues={'1000','0','0.01','0.9','1.1'};

PARAMS=inputdlg(Prompt,Title,1,DefaultValues);
pause(0.1);

MaxEpoch=str2num(PARAMS{1});                %#ok
ErrorGoal=str2num(PARAMS{2});               %#ok
InitialStepSize=str2num(PARAMS{3});         %#ok
StepSizeDecreaseRate=str2num(PARAMS{4});    %#ok
StepSizeIncreaseRate=str2num(PARAMS{5});    %#ok
TrainOptions=[MaxEpoch ...
              ErrorGoal ...
              InitialStepSize ...
              StepSizeDecreaseRate ...
              StepSizeIncreaseRate];

DisplayInfo=true;
DisplayError=true;
DisplayStepSize=true;
DisplayFinalResult=true;
DisplayOptions=[DisplayInfo ...
                DisplayError ...
                DisplayStepSize ...
                DisplayFinalResult];

OptimizationMethod=1;
% 0: Backpropagation
% 1: Hybrid
            
fis=anfis([TrainInputs TrainTargets],fis,TrainOptions,DisplayOptions,[],OptimizationMethod);

pause(0.1);
%% Apply ANFIS to Train Data

TrainOutputs=evalfis(TrainInputs,fis);

TrainErrors=TrainTargets-TrainOutputs;
TrainMSE=mean(TrainErrors(:).^2);
TrainRMSE=sqrt(TrainMSE);
TrainErrorMean=mean(TrainErrors);
TrainErrorSTD=std(TrainErrors);

figure;
PlotResults(TrainTargets,TrainOutputs,'Train Data');
axis tight
figure;
plotregression(TrainTargets,TrainOutputs,'Train Data');
axis tight
set(gcf,'Toolbar','figure');
grid

%% Apply ANFIS to Test Data

TestOutputs=evalfis(TestInputs,fis);
TestErrors=TestTargets-TestOutputs;
TestMSE=mean(TestErrors(:).^2);
TestRMSE=sqrt(TestMSE);
TestErrorMean=mean(TestErrors);
TestErrorSTD=std(TestErrors);

figure;
PlotResults(TestTargets,TestOutputs,'Test Data');
axis tight
grid on
figure;
plotregression(TestTargets,TestOutputs,'Test Data');
axis tight
set(gcf,'Toolbar','figure');
grid on
MaxErrorTrain=max(abs(TrainErrors))%#ok
MaxErrorTest=max(abs(TestErrors)) %#ok

%anfisedit(fis)
pause(0.1);
%% wavelet plots

[A, D]=GetDWT(g',nLevel,wname);

figure;

subplot(nLevel+1,2,1);
plot(g');
axis tight
grid on
ylabel('GL (m)');
subplot(nLevel+1,2,2);
plot(g');
axis tight
grid on
ylabel('GL (m)');

c=2;
for i=1:nLevel
    c=c+1;
    subplot(nLevel+1,2,c);
    plot(A{i});
    axis tight
    grid on
    ylabel(['a_{' num2str(i) '}']);
    
    c=c+1;
    subplot(nLevel+1,2,c);
    plot(D{i});
    axis tight
    grid on
    ylabel(['d_{' num2str(i) '}']);
end


[A, D]=GetDWT(p',nLevel,wname);

figure;

subplot(nLevel+1,2,1);
plot(p');
axis tight
grid on
ylabel('Rainfall(mm)');

subplot(nLevel+1,2,2);
plot(p');
axis tight
grid on
ylabel('Rainfall(mm)');

c=2;
for i=1:nLevel
    c=c+1;
    subplot(nLevel+1,2,c);
    plot(A{i});
    axis tight
    grid on
    ylabel(['a_{' num2str(i) '}']);
    
    c=c+1;
    subplot(nLevel+1,2,c);
    plot(D{i});
    axis tight
    grid on
    ylabel(['d_{' num2str(i) '}']);
end
%wavemenu

