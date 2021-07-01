function [trial_avg_resp_trace, trial_avg_whole_trace] = averageTrials_JGUcourse(responses,stimTrace,frameRate)
% averageTrials()  Averages the trials of epochs and returns the
%                  averaged time traces.
%   
                               
stim_coords = findTrialCoords_JGUcourse(stimTrace);


base_dur = 4; % Hard coded for sine gratings

% Trial averaging
for iROI = 1:size(responses,1)
     
    curr_trace = responses(iROI,:);
    % Compute the lengths
    % Initialize the randomization related variables
    baseline_epoch = 'Epoch_0';
    resp_start_idx = 2;
    resp_end_idx = 3;
    base_start_idx = 1;
    base_end_idx = 4;

    
    base_len = floor(base_dur*frameRate);

    epochs = fields(stim_coords);   
    
    for iEpoch = 1:length(epochs)
        epoch = epochs{iEpoch};
        if epoch == baseline_epoch % Skip the baseline epoch
            continue
        end

        epoch_dur = 4;

        resp_len = floor(epoch_dur*frameRate);
        trial_len = base_len + resp_len + base_len;
        % resp_len = np.min((trial_c(resp_end_idx)-trial_c(resp_start_idx) for trial_c in epoch_coords))
        % trial_len = np.min((trial_c(base_end_idx)-trial_c(base_start_idx) for trial_c in epoch_coords))

        epoch_coords = stim_coords.(epoch);
        trial_num = length(epoch_coords);
        resp_mat = zeros(resp_len,trial_num);
        trial_mat =zeros(trial_len,trial_num);
        % Go over trials
        for iTrial = 1:trial_num
            
            trial_coords = epoch_coords{iTrial};
            resp_start = trial_coords(resp_start_idx);
            trial_start = trial_coords(base_start_idx);
            resp_mat(:,iTrial) = curr_trace(resp_start:resp_start+resp_len-1);
            trial_mat(:,iTrial) = curr_trace(trial_start:trial_start+trial_len-1);
        end
        if ~(exist('trial_avg_resp_trace','var'))
            trial_avg_resp_trace = zeros(size(responses,1),resp_len,length(epochs)-1);
            trial_avg_whole_trace = zeros(size(responses,1),trial_len,length(epochs)-1);
   
        end
        
        % Add the responses to the ROI
        trial_avg_resp_trace(iROI,:,iEpoch-1) = mean(resp_mat,2)';
        trial_avg_whole_trace(iROI,:,iEpoch-1) = mean(trial_mat,2)';
        

        
    end
  

end