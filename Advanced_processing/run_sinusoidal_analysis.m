%% Analysis for sinusoidals with 100% contrast and different luminances
close all
clear all
dirPath=uigetdir(pwd, 'Select the image folder');
cd(dirPath); 

data_f = dir('*_processed.mat');
data = load(data_f.name);
data = data.processedData;

luminances = [0.0625,0.1250,0.25,0.3750,0.5]; 
%% Compute dF/F
roi_num = length(data.masks);

dfTraces = zeros(size(data.signals));

for iROI = 1:roi_num    
    dfTraces(iROI,:) = data.signals(iROI,:)/mean(data.signals(iROI,:)) -1;
end

figure;
title('ROI normalized responses')
plot(data.stimTrace'*max(max(dfTraces))/max(data.stimTrace),'--k','LineWidth',2,...
    'DisplayName','stimulus')
legend()
hold on;
plot(dfTraces','LineWidth',.5)
xlabel('Frames')
ylabel('Responses (dF/F)')
title('Response traces of ROIs')

%% Trial averaging
[trial_avg_resp_trace, trial_avg_whole_trace] = ...
    averageTrials_JGUcourse(dfTraces,data.stimTrace,data.frameRate);

time_trace = 1:size(trial_avg_resp_trace,2);
time_trace = time_trace/data.frameRate;
time_trace = time_trace-time_trace(1);

figure
for iEpoch = 1:size(trial_avg_resp_trace,3)
    
    subplot(2,3,iEpoch)
    plot(time_trace,trial_avg_resp_trace(:,:,iEpoch),'LineWidth',1)
    xlabel('Time (s)')
    ylabel('Responses (dF/F)')
    title(sprintf('Luminance: %.4f',luminances(iEpoch)))
    
end
linkaxes()

%% Calculate contrast response
% Fourier transform to get contrast responses

lum = size(trial_avg_resp_trace,3);
nr_rois = size(trial_avg_resp_trace,1);
contrast_response = nan(nr_rois,lum);

for x = 1:nr_rois
    for z = 1:lum
        current_trace = trial_avg_resp_trace(x,:,z);
  
        % Information about imaging - trace
        Fs = data.frameRate;                    % Sampling frequency                    
        T = 1/Fs;                   % Sampling period       
        L = length(current_trace);  % Length of trace

        % Compute FFT and find 1Hz response
        Y = fft(current_trace);
        P2 = abs(Y/L);
        P1 = P2(1:L/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs*(0:(L/2))/L;
        % plot(f,P1) 
        % title('Single-Sided Amplitude Spectrum of X(t)')
        % xlabel('f (Hz)')
        % ylabel('|P1(f)|')

        [b, oneHz_index] = min(abs(f-1));
        contrast_response(x,z) = P1(oneHz_index);
    end
end
%% Plot contrast response
figure
plot(luminances,contrast_response,'-o','LineWidth',2)
xlabel('Luminance')
ylabel('Contrast response')
ylim([0, max(max(contrast_response))+0.1])
title('Contrast response of each ROI')


figure
mean_r = mean(contrast_response);
std_r = std(contrast_response);
plot(luminances,contrast_response,'-o','LineWidth',1,'Color',[0 0 0 .3])
hold on; 
errorbar(luminances,mean_r,std_r,'-o','LineWidth',3,'DisplayName','mean')
xlabel('Luminance')
ylabel('Contrast response')
ylim([0, max(max(contrast_response))+0.1])
title('Mean response')
legend()